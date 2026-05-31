from rest_framework import serializers

from documents.models import Document


class ReviewQueueSerializer(
    serializers.ModelSerializer
):

    class Meta:

        model = Document

        fields = [
            "id",
            "filename",
            "predicted_class",
            "confidence_score",
            "status",
            "uploaded_at",
        ]