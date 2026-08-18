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
    word_count = len(cleaned_text.split())

    if not cleaned_text or word_count < 20:
        return True

    try:
        with fitz.open(pdf_path) as doc:
            if len(doc) == 0:
                return False

            text_ratio_scores = []
            image_page_count = 0

            for page in doc:
                page_text = clean_text(page.get_text("text"))
                page_word_count = len(page_text.split())
                page_image_count = len(page.get_images(full=True))

                if page_image_count > 0:
                    image_page_count += 1

                if page_word_count == 0:
                    text_ratio_scores.append(0.0)
                else:
                    text_ratio_scores.append(page_word_count)

            if image_page_count > len(doc) // 2:
                return True

            if len(text_ratio_scores) > 0:
                average_page_text = sum(text_ratio_scores) / len(text_ratio_scores)
                low_text_pages = sum(1 for score in text_ratio_scores if score < 10)

                if average_page_text < 15 and low_text_pages / len(text_ratio_scores) > 0.5:
                    return True

            if word_count < 40:
                return True

    except Exception:
        return False

    return False


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
    sidecar = Path(temp_dir) / "ocr_output.txt"

    try:
        command = command_prefix + [
            "--deskew",
            "--force-ocr",
            "--output-type",
            "pdf",
            "--sidecar",
            str(sidecar),
            str(pdf_path),
            str(output_pdf),
        ]

        completed = subprocess.run(
            command,
            capture_output=True,
            text=True,
            check=False,
            timeout=300,
        )

        if completed.returncode != 0:
            raise RuntimeError(completed.stderr.strip() or completed.stdout.strip())

        if sidecar.exists():
            return sidecar.read_text(encoding="utf-8", errors="ignore")

        return None

    finally:
        shutil.rmtree(temp_dir, ignore_errors=True)


def extract_text(pdf_path):

    text = _extract_with_fitz(pdf_path)
    cleaned_text = clean_text(text)

    if not _needs_ocr(pdf_path, cleaned_text):
        return cleaned_text

    try:
        ocr_text = clean_text(_run_ocr(pdf_path))
    except Exception:
        # Preserve usable embedded text in partially scanned PDFs. For a fully
        # scanned PDF, expose the OCR error instead of feeding empty text into
        # classification and the LLM.
        if cleaned_text:
            return cleaned_text
        raise

    if ocr_text:
        return ocr_text
    if cleaned_text:
        return cleaned_text

    raise RuntimeError("OCR completed but extracted no readable text from the PDF.")
