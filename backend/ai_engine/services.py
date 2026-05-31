from .pdf_extractor import extract_text
from .qwen_service import analyze_document
from .classifier import (
    classify_document,
    needs_human_review
)


def process_document(document):

    # Extract text

    text = extract_text(
        document.uploaded_file.path
    )

    document.extracted_text = text

    # LLM analysis

    ai_result = analyze_document(
        text
    )

    document.summary = ai_result.get(
        "summary",
        ""
    )

    document.keywords = ai_result.get(
        "keywords",
        []
    )

    document.suggested_department = ai_result.get(
        "department",
        "Unknown"
    )

    # Machine Learning Classification

    classification = classify_document(
        text
    )

    document.predicted_class = classification[
        "department"
    ]

    document.confidence_score = classification[
        "confidence"
    ]

    # HITL Decision

    if needs_human_review(
        document.confidence_score
    ):

        document.human_review_required = True

        document.status = "review"

        document.final_class = ""

    else:

        document.human_review_required = False

        document.status = "approved"

        document.final_class = (
            document.predicted_class
        )

    document.save()

    return document