from .pdf_extractor import extract_text
import re
from collections import Counter
from .classifier import (
    classify_document,
    needs_human_review
)
from .qwen_service import analyze_document


def _local_metadata(text):
    """Provide useful metadata when Ollama is temporarily unavailable."""
    clean_text = " ".join(text.split())
    sentences = re.split(r"(?<=[.!?])\s+", clean_text)
    summary = " ".join(sentences[:3])[:700]

    stop_words = {
        "about", "after", "also", "and", "are", "been", "before",
        "being", "between", "document", "for", "from", "have", "into",
        "that", "the", "their", "this", "was", "were", "which", "with",
    }
    words = re.findall(r"[A-Za-z][A-Za-z-]{3,}", clean_text.lower())
    keywords = [
        word for word, _ in Counter(
            word for word in words if word not in stop_words
        ).most_common(8)
    ]
    return summary, keywords


def process_document(document):

    decision_threshold = 70.0

    # Extract text

    text = extract_text(
        document.uploaded_file.path
    )

    document.extracted_text = text

    # Machine Learning Classification

    classification = classify_document(
        text
    )

    document.predicted_class = classification.get(
        "predicted_class",
        classification.get("department", "")
    )

    document.confidence_score = classification.get(
        "confidence",
        0
    )
    document.second_class = classification.get(
        "second_class",
        ""
    )
    document.second_confidence = classification.get(
        "second_confidence",
        0
    )
    document.confidence_margin = classification.get(
        "confidence_margin",
        0
    )

    # Ollama generates the document metadata. Keep a deterministic fallback so
    # an Ollama restart does not prevent the upload itself from being saved.
    fallback_summary, fallback_keywords = _local_metadata(text)
    try:
        ai_analysis = analyze_document(text)
    except Exception as error:
        print(f"Ollama analysis error: {error}")
        ai_analysis = {}

    ai_summary = ai_analysis.get("summary")
    document.summary = (
        ai_summary.strip()[:700]
        if isinstance(ai_summary, str) and ai_summary.strip()
        else fallback_summary
    )

    ai_keywords = ai_analysis.get("keywords")
    document.keywords = (
        [str(keyword).strip() for keyword in ai_keywords if str(keyword).strip()][:8]
        if isinstance(ai_keywords, list) and ai_keywords
        else fallback_keywords
    )

    ai_department = ai_analysis.get("department")
    valid_departments = {"HR", "Finance", "Legal", "IT", "Procurement", "Operations"}
    document.suggested_department = (
        ai_department if ai_department in valid_departments
        else document.predicted_class
    )

    # HITL Decision

    if needs_human_review(
        document.confidence_score,
        auto_accept_threshold=decision_threshold
    ):

        document.human_review_required = True
        document.decision_route = "human_review"

        document.status = "review"

        document.final_class = ""

    else:

        document.human_review_required = False
        document.decision_route = "auto_approved"

        document.status = "approved"

        document.final_class = (
            document.predicted_class
        )

    document.decision_threshold = decision_threshold

    document.save()

    return document
