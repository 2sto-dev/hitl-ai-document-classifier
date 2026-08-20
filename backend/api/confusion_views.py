from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import (
    IsAuthenticated
)

from documents.models import Document


DEPARTMENTS = [
    "HR",
    "Finance",
    "IT",
    "Legal",
    "Operations",
    "Procurement"
]


class AccuracyStatisticsView(
    APIView
):

    permission_classes = [IsAuthenticated]

    def get(
        self,
        request
    ):

        reviewed_docs = (
            Document.objects.filter(
                owner=request.user
            ).exclude(
                final_class=""
            )
        )

        total_reviewed = (
            reviewed_docs.count()
        )

        correct_predictions = (
            reviewed_docs.filter(
                human_corrected=False
            ).count()
        )

        human_corrections = (
            reviewed_docs.filter(
                human_corrected=True
            ).count()
        )

        accuracy = 0

        if total_reviewed > 0:

            accuracy = (
                correct_predictions /
                total_reviewed
            ) * 100

        return Response({

            "total_reviewed":
                total_reviewed,

            "correct_predictions":
                correct_predictions,

            "human_corrections":
                human_corrections,

            "accuracy":
                round(
                    accuracy,
                    2
                )

        })


class ConfusionMatrixView(
    APIView
):

    permission_classes = [IsAuthenticated]

    def get(
        self,
        request
    ):

        matrix = {}

        documents = Document.objects.filter(owner=request.user)

        for predicted in DEPARTMENTS:

            matrix[predicted] = {}

            for actual in DEPARTMENTS:

                count = (
                    documents.filter(
                        predicted_class=predicted,
                        final_class=actual
                    ).count()
                )

                matrix[predicted][actual] = count

        return Response(matrix)
