from rest_framework import serializers


class ReviewSerializer(
    serializers.Serializer
):

    final_class = serializers.CharField()

    review_notes = serializers.CharField(
        required=False,
        allow_blank=True
    )