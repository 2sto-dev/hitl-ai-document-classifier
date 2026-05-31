from django.utils import timezone


def approve_document(
    document,
    reviewer,
    department,
    notes=""
):

    document.final_class = department

    document.review_notes = notes

    document.reviewed_by = reviewer

    document.reviewed_at = timezone.now()

    document.human_review_required = False

    document.status = "approved"

    document.save()

    return document