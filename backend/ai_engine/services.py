from .pdf_extractor import extract_text
import re
from collections import Counter
from .classifier import (
    classify_document,
    needs_human_review
)


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

    # Keep upload latency low. The interactive AI endpoint handles optional
    # LLM questions; ingestion uses deterministic local metadata instead.
    clean_text = " ".join(text.split())
    sentences = re.split(r"(?<=[.!?])\s+", clean_text)
    document.summary = " ".join(sentences[:3])[:700]

    stop_words = {
        "about", "after", "also", "and", "are", "been", "before",
        "being", "between", "document", "for", "from", "have", "into",
        "that", "the", "their", "this", "was", "were", "which", "with",
    }
    words = re.findall(r"[A-Za-z][A-Za-z-]{3,}", clean_text.lower())
    document.keywords = [
        word for word, _ in Counter(
            word for word in words if word not in stop_words
        ).most_common(8)
    ]
    document.suggested_department = document.predicted_class

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
