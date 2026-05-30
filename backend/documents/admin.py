from django.contrib import admin

from .models import Document


@admin.register(Document)
class DocumentAdmin(admin.ModelAdmin):

    list_display = (
        "filename",
        "status",
        "confidence_score",
        "uploaded_at",
    )

    readonly_fields = (
        "extracted_text",
        "predicted_class",
        "confidence_score",
    )