from django.db.models import Count

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import (
    IsAuthenticated
)

from documents.models import Document


class ReviewerStatisticsView(
    APIView
):

    permission_classes = [
        IsAuthenticated
    ]

    def get(
        self,
        request
    ):

        reviewers = (
            Document.objects
            .exclude(reviewed_by="")
            .values("reviewed_by")
            .annotate(
                reviewed_count=Count("id")
            )
            .order_by(
                "-reviewed_count"
            )
        )

        return Response(
            list(reviewers)
        )


class ReviewerCorrectionView(
    APIView
):

    permission_classes = [
        IsAuthenticated
    ]

    def get(
        self,
        request
    ):

        reviewers = (
            Document.objects
            .filter(
                human_corrected=True
            )
            .exclude(
                reviewed_by=""
            )
            .values(
                "reviewed_by"
            )
            .annotate(
                correction_count=Count(
                    "id"
                )
            )
            .order_by(
                "-correction_count"
            )
        )

        return Response(
            list(reviewers)
        )