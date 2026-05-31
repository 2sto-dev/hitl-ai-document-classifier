from rest_framework import serializers


class UploadDocumentSerializer(
    serializers.Serializer
):

    filename = serializers.CharField()

    uploaded_file = serializers.FileField()