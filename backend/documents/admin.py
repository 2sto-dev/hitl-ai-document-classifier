from django.contrib import admin

from .models import Document


@admin.action(
    description="Approve selected documents"
)
def approve_documents(
    modeladmin,
    request,
    queryset
):

    for document in queryset:

        if not document.final_class:

            document.final_class = (
                document.predicted_class
            )

        document.status = "approved"

        document.reviewed_by = (
            request.user.username
        )

        document.human_review_required = False

        document.save()


@admin.action(
    description="Mark selected documents for review"
)
def mark_for_review(
    modeladmin,
    request,
    queryset
):

    for document in queryset:

        document.status = "review"

        document.human_review_required = True

        document.save()


@admin.register(Document)
class DocumentAdmin(admin.ModelAdmin):

    list_display = (
        "filename",
        "predicted_class",
        "final_class",
        "confidence_score",
        "status",
        "human_review_required",
        "reviewed_by",
        "uploaded_at"
    )

    list_filter = (
        "status",
        "human_review_required",
        "predicted_class",
        "final_class"
    )

    search_fields = (
        "filename",
        "predicted_class",
        "final_class"
    )

    readonly_fields = (
        "summary",
        "keywords",
        "predicted_class",
        "confidence_score",
        "uploaded_at",
        "updated_at",
        "extracted_text"
    )

    actions = [
        approve_documents,
        mark_for_review
    ]

    fieldsets = (

        (
            "Document",
            {
                "fields": (
                    "filename",
                    "uploaded_file"
                )
            }
        ),

        (
            "AI Analysis",
            {
                "fields": (
                    "summary",
                    "keywords",
                    "suggested_department",
                    "predicted_class",
                    "confidence_score"
                )
            }
        ),

        (
            "Human Review",
            {
                "fields": (
                    "final_class",
                    "status",
                    "human_review_required",
                    "review_notes",
                    "reviewed_by",
                    "reviewed_at"
                )
            }
        ),

        (
            "Extracted Text",
            {
                "fields": (
                    "extracted_text",
                ),
                "classes": (
                    "collapse",
                )
            }
        ),

        (
            "Metadata",
            {
                "fields": (
                    "uploaded_at",
                    "updated_at"
                )
            }
        ),
    )