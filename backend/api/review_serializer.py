from rest_framework import serializers

from documents.models import Document


class ReviewSerializer(
    serializers.Serializer
):

    action = serializers.ChoiceField(
        choices=[
            ('approve', 'Approve'),
            ('change', 'Change'),
            ('reject', 'Reject'),
        ]
    )

    final_class = serializers.ChoiceField(
        choices=Document.DEPARTMENT_CHOICES,
        required=False,
        allow_blank=True
    )

    review_notes = serializers.CharField(
        required=False,
        allow_blank=True
    )

    def validate(self, attrs):
        if attrs["action"] == "change" and not attrs.get("final_class"):
            raise serializers.ValidationError({
                "final_class": "This field is required when changing the class."
            })

        return attrs
