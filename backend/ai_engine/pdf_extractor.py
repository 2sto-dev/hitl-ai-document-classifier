import os
import re
import shutil
import subprocess
import sys
import tempfile
import unicodedata
from importlib.util import find_spec
from pathlib import Path

import fitz


class OCRUnavailableError(RuntimeError):
    """Raised when a scanned PDF needs OCR but no OCR engine is available."""


EMAIL_RE = re.compile(r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b")
PHONE_RE = re.compile(
    r"(?<!\w)(?:\+?\d{1,3}[-.\s]?)?(?:\(?\d{2,4}\)?[-.\s]?){2,4}\d{2,4}(?!\w)"
)


def preprocess_text(
    text,
    *,
    mask_pii=False,
    remove_repeated_headers_footers=False,
):
    if not text:
        return ""

    text = unicodedata.normalize("NFKC", text)

    # Remove obvious control characters and zero-width markers without stripping
    # meaningful business/legal terms.
    text = text.replace("\x00", " ")
    text = text.replace("\x0b", " ")
    text = text.replace("\x0c", " ")
    text = text.replace("\u200b", "")
    text = text.replace("\ufeff", "")
    text = text.replace("\u00ad", "")

    # Normalize line endings and whitespace in a deterministic way.
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    text = re.sub(r"[\u00a0\t]+", " ", text)
    text = re.sub(r"\n{3,}", "\n\n", text)

    if remove_repeated_headers_footers:
        lines = text.splitlines()
        cleaned_lines = []
        i = 0

        while i < len(lines):
            line = lines[i].strip()
            if not line:
                cleaned_lines.append("")
                i += 1
                continue

            j = i + 1
            while j < len(lines) and lines[j].strip() == line:
                j += 1

            if j - i >= 3 and len(line.split()) <= 6:
                i = j
                continue

            cleaned_lines.append(line)
            i = j

        text = "\n".join(cleaned_lines)

    text = re.sub(r"(?<!\w)\n(?!\w)", "\n", text)
    text = re.sub(r"(?<=\w)\n(?=\w)", " ", text)
    text = re.sub(r"[ ]{2,}", " ", text)
    text = re.sub(r"\n[ \t]+", "\n", text)
    text = re.sub(r"[ \t]+\n", "\n", text)

    if mask_pii:
        text = EMAIL_RE.sub("[REDACTED_EMAIL]", text)
        text = PHONE_RE.sub("[REDACTED_PHONE]", text)

    # Normalize spacing once more after optional cleanup steps.
    text = re.sub(r"\s+", " ", text)
    text = re.sub(r"\n+", "\n", text)
    text = text.strip()

    return text


def clean_text(text, **kwargs):
    return preprocess_text(text, **kwargs)


def _extract_with_fitz(pdf_path):

    with fitz.open(pdf_path) as doc:
        page_texts = []

        for page in doc:
            page_text = page.get_text("text")
            cleaned_page_text = clean_text(page_text)

            if cleaned_page_text:
                page_texts.append(cleaned_page_text)

        return " ".join(page_texts)


def _needs_ocr(pdf_path, text):
    cleaned_text = clean_text(text)
    total_words = len(cleaned_text.split())

    if total_words < 20:
        return True

    try:
        with fitz.open(pdf_path) as doc:
            page_count = len(doc)

            if page_count == 0:
                return False

            page_word_counts = []

            for page in doc:
                page_text = clean_text(page.get_text("text"))
                page_word_counts.append(len(page_text.split()))

            average_words = sum(page_word_counts) / page_count
            empty_pages = sum(words == 0 for words in page_word_counts)
            low_text_pages = sum(words < 10 for words in page_word_counts)

            empty_ratio = empty_pages / page_count
            low_text_ratio = low_text_pages / page_count

            # Logos and decorative images must not trigger OCR when the PDF
            # already contains enough digital text.
            if (
                total_words >= 80
                and average_words >= 20
                and empty_ratio < 0.30
            ):
                return False

            return (
                total_words < 40
                or empty_ratio >= 0.30
                or (average_words < 15 and low_text_ratio > 0.50)
            )

    except Exception as exc:
        print(f"OCR detection failed for {pdf_path}: {exc}")
        return total_words < 20


def _run_ocr(pdf_path):
    ocrmypdf_executable = shutil.which("ocrmypdf")
    if ocrmypdf_executable:
        command_prefix = [ocrmypdf_executable]
    elif find_spec("ocrmypdf") is not None:
        # On Windows, the virtual environment's Scripts directory is not
        # always on PATH, so use the same interpreter that runs Django.
        command_prefix = [sys.executable, "-m", "ocrmypdf"]
    else:
        raise OCRUnavailableError(
            "This PDF contains no readable text and requires OCR, but "
            "OCRmyPDF is not installed. Install backend/requirements.txt "
            "and ensure Tesseract OCR is installed and available."
        )

    temp_dir = tempfile.mkdtemp(prefix="hitl_ocr_")
    output_pdf = Path(temp_dir) / "ocr_output.pdf"

    try:
        command = command_prefix + [
            "--deskew",
            "--rotate-pages",
            "--skip-text",
            "--language",
            os.environ.get("OCR_LANGUAGES", "ron+eng"),
            "--jobs",
            "2",
            "--optimize",
            "0",
            "--output-type",
            "pdf",
            str(pdf_path),
            str(output_pdf),
        ]

        completed = subprocess.run(
            command,
            capture_output=True,
            text=True,
            check=False,
            timeout=180,
        )

        if completed.returncode != 0:
            error = completed.stderr.strip() or completed.stdout.strip()
            raise RuntimeError(error)

        if not output_pdf.exists():
            raise RuntimeError("OCRmyPDF did not create the output PDF")

        # The output contains existing digital text plus text added to
        # image-only pages by OCRmyPDF.
        return _extract_with_fitz(output_pdf)

    finally:
        shutil.rmtree(temp_dir, ignore_errors=True)


def extract_text(pdf_path):
    native_text = _extract_with_fitz(pdf_path)
    cleaned_native_text = clean_text(native_text)

    if not _needs_ocr(pdf_path, cleaned_native_text):
        return cleaned_native_text

    try:
        ocr_text = _run_ocr(pdf_path)

        if ocr_text:
            return clean_text(ocr_text)

    except subprocess.TimeoutExpired:
        print(f"OCR timed out for {pdf_path}")

    except Exception as exc:
        print(f"OCR fallback failed for {pdf_path}: {exc}")

    return cleaned_native_text
