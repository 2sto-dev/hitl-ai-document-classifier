from django.utils import timezone

from rest_framework import generics
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import (
    IsAuthenticated
)

from rest_framework.parsers import (
    MultiPartParser,
    FormParser
)

from documents.models import Document

from .serializers import (
    DocumentSerializer
)

from .review_serializer import (
    ReviewSerializer
)

from .upload_serializer import (
    UploadDocumentSerializer
)

from .review_queue_serializer import (
    ReviewQueueSerializer
)
from django.views.decorators.csrf import csrf_exempt

from ai_engine.qwen_service import analyze_document


class DocumentListView(
    generics.ListAPIView
):

    permission_classes = [IsAuthenticated]

    queryset = (
        Document.objects.all()
        .order_by("-uploaded_at")
    )

    serializer_class = (
        DocumentSerializer
    )


class DocumentDetailView(
    generics.RetrieveAPIView
):

    permission_classes = [IsAuthenticated]

    queryset = (
        Document.objects.all()
    )

    serializer_class = (
        DocumentSerializer
    )

    lookup_field = "id"


class ReviewQueueView(
    generics.ListAPIView
):

    permission_classes = [IsAuthenticated]

    serializer_class = (
        ReviewQueueSerializer
    )

    queryset = (
        Document.objects.filter(
            human_review_required=True
        )
        .order_by("-uploaded_at")
    )


class ReviewDocumentView(
    APIView
):

    permission_classes = [IsAuthenticated]

    def post(
        self,
        request,
        id
    ):

        document = Document.objects.get(
            id=id
        )

        serializer = ReviewSerializer(
            data=request.data
        )

        serializer.is_valid(
            raise_exception=True
        )

        action = serializer.validated_data[
            "action"
        ]

        final_class = serializer.validated_data.get(
            "final_class",
            ""
        )

        if action == "approve":
            selected_class = document.predicted_class
            document.status = "approved"
        elif action == "change":
            selected_class = final_class
            document.status = "approved"
        else:
            selected_class = ""
            document.status = "rejected"

        document.final_class = selected_class

        document.human_corrected = (
            selected_class != document.predicted_class
        )

        document.review_notes = (
            serializer.validated_data.get(
                "review_notes",
                ""
            )
        )

        document.reviewed_by = (
            request.user.username
            if hasattr(request, 'user') and request.user
            else 'anonymous'
        )

        document.reviewed_at = (
            timezone.now()
        )

        document.human_review_required = False

        document.save()

        return Response(
            {
                "message":
                    "Document reviewed successfully",

                "reviewed_by":
                    request.user.username,

                "final_class":
                    document.final_class,

                "predicted_class":
                    document.predicted_class,

                "human_corrected":
                    document.human_corrected
            },
            status=status.HTTP_200_OK
        )


class UploadDocumentView(
    APIView
):

    permission_classes = [IsAuthenticated]

    parser_classes = [
        MultiPartParser,
        FormParser
    ]

    def post(
        self,
        request
    ):

        serializer = (
            UploadDocumentSerializer(
                data=request.data
            )
        )

        serializer.is_valid(
            raise_exception=True
        )

        document = Document.objects.create(

            filename=serializer.validated_data[
                "filename"
            ],

            uploaded_file=serializer.validated_data[
                "uploaded_file"
            ]
        )

        return Response(
            {
                "id": str(document.id),
                "filename": document.filename,
                "uploaded_by": request.user.username,
                "message":
                    "Document uploaded successfully"
            },
            status=status.HTTP_201_CREATED
        )


class AnalyzeAiView(APIView):

    permission_classes = [IsAuthenticated]

    def post(self, request):
        # Accept a plain text prompt and optional context
        text = request.data.get('text', '')

        if not text:
            return Response({'error': 'No text provided'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            result = analyze_document(text)
            return Response(result, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
