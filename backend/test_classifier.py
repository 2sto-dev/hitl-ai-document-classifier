from ai_engine.classifier import (
    classify_document,
    needs_human_review
)

result = classify_document(
    text="Employment agreement",
    suggested_department="HR"
)

print(result)

print(
    needs_human_review(
        result["confidence"]
    )
)