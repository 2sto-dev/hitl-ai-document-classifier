from django.db.models import Avg, Count, F

from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated

from documents.models import Document


class StatisticsView(
    APIView
):

    permission_classes = [IsAuthenticated]

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

        average_margin = (
            Document.objects.aggregate(
                Avg(
                    "confidence_margin"
                )
            )[
                "confidence_margin__avg"
            ]
            or 0
        )

        high_confidence_docs = Document.objects.filter(
            confidence_score__gte=95.0
        ).count()

        low_margin_docs = Document.objects.filter(
            confidence_margin__lt=0.30
        ).count()

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

        processed_documents = (
            Document.objects.exclude(
                status="pending"
            ).count()
        )

        auto_approved_documents = (
            Document.objects.filter(
                status="approved",
                reviewed_at=None
            ).count()
        )

        human_intervention_rate = 0

        if processed_documents > 0:

            human_intervention_rate = (
                reviewed_documents /
                processed_documents
            ) * 100

        auto_approval_rate = 0

        if processed_documents > 0:

            auto_approval_rate = (
                auto_approved_documents /
                processed_documents
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

            "average_margin":
                round(
                    average_margin,
                    2
                ),

            "high_confidence_docs":
                high_confidence_docs,

            "low_margin_docs":
                low_margin_docs,

            "human_corrected":
                human_corrected,

            "reviewed_documents":
                reviewed_documents,

            "processed_documents":
                processed_documents,

            "auto_approved_documents":
                auto_approved_documents,

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

    permission_classes = [IsAuthenticated]

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
