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

        documents = Document.objects.filter(owner=request.user)

        total_documents = (
            documents.count()
        )

        approved = (
            documents.filter(
                status="approved"
            ).count()
        )

        review_required = (
            documents.filter(
                status="review"
            ).count()
        )

        rejected = (
            documents.filter(
                status="rejected"
            ).count()
        )

        pending = (
            documents.filter(
                status="pending"
            ).count()
        )

        average_confidence = (
            documents.aggregate(
                Avg(
                    "confidence_score"
                )
            )[
                "confidence_score__avg"
            ]
            or 0
        )

        average_margin = (
            documents.aggregate(
                Avg(
                    "confidence_margin"
                )
            )[
                "confidence_margin__avg"
            ]
            or 0
        )

        high_confidence_docs = documents.filter(
            confidence_score__gte=95.0
        ).count()

        low_margin_docs = documents.filter(
            confidence_margin__lt=0.30
        ).count()

        human_corrected = (
            documents.filter(
                human_corrected=True
            ).count()
        )

        reviewed_documents = (
            documents.exclude(
                reviewed_at=None
            ).count()
        )

        processed_documents = (
            documents.exclude(
                status="pending"
            ).count()
        )

        auto_approved_documents = (
            documents.filter(
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

        documents = Document.objects.filter(owner=request.user)

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
                documents.filter(
                    final_class=department
                ).count()
            )

        return Response(data)
