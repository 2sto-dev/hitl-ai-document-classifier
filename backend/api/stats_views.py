from django.db.models import Avg

from rest_framework.response import Response
from rest_framework.views import APIView

from documents.models import Document


class StatisticsView(
    APIView
):

    permission_classes = []

    def get(
        self,
        request
    ):

        total_documents = (
            Document.objects.count()
        )

        approved = (
            Document.objects.filter(
                status="approved"
            ).count()
        )

        review_required = (
            Document.objects.filter(
                status="review"
            ).count()
        )

        rejected = (
            Document.objects.filter(
                status="rejected"
            ).count()
        )

        pending = (
            Document.objects.filter(
                status="pending"
            ).count()
        )

        average_confidence = (
            Document.objects.aggregate(
                Avg(
                    "confidence_score"
                )
            )[
                "confidence_score__avg"
            ]
            or 0
        )

        human_corrected = (
            Document.objects.filter(
                human_corrected=True
            ).count()
        )

        reviewed_documents = (
            Document.objects.exclude(
                reviewed_at=None
            ).count()
        )

        human_intervention_rate = 0

        if total_documents > 0:

            human_intervention_rate = (
                review_required /
                total_documents
            ) * 100

        auto_approval_rate = 0

        if total_documents > 0:

            auto_approval_rate = (
                approved /
                total_documents
            ) * 100

        return Response({

            "total_documents":
                total_documents,

            "approved":
                approved,

            "review_required":
                review_required,

            "rejected":
                rejected,

            "pending":
                pending,

            "average_confidence":
                round(
                    average_confidence,
                    2
                ),

            "human_corrected":
                human_corrected,

            "reviewed_documents":
                reviewed_documents,

            "human_intervention_rate":
                round(
                    human_intervention_rate,
                    2
                ),

            "auto_approval_rate":
                round(
                    auto_approval_rate,
                    2
                )

        })


class DepartmentStatisticsView(
    APIView
):

    permission_classes = []

    def get(
        self,
        request
    ):

        data = {}

        departments = [

            "HR",
            "Finance",
            "IT",
            "Legal",
            "Operations",
            "Procurement"

        ]

        for department in departments:

            data[
                department
            ] = (
                Document.objects.filter(
                    final_class=department
                ).count()
            )

        return Response(data)