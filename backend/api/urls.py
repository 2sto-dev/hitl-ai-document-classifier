from django.urls import path

from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
)

from .auth_views import (
    RegisterView,
    UserProfileView,
)

from .views import (
    DocumentListView,
    DocumentDetailView,
    ReviewQueueView,
    ReviewDocumentView,
    UploadDocumentView,
    AnalyzeAiView,
)

from .stats_views import (
    StatisticsView,
    DepartmentStatisticsView
)

from .reviewer_stats_views import (
    ReviewerStatisticsView,
    ReviewerCorrectionView
)

from .confusion_views import (
    AccuracyStatisticsView,
    ConfusionMatrixView
)


urlpatterns = [

    # ==========================
    # Authentication
    # ==========================

    path(
        "auth/register/",
        RegisterView.as_view(),
        name="register"
    ),

    path(
        "auth/login/",
        TokenObtainPairView.as_view(),
        name="token_obtain_pair"
    ),

    path(
        "auth/refresh/",
        TokenRefreshView.as_view(),
        name="token_refresh"
    ),

    path(
        "auth/me/",
        UserProfileView.as_view(),
        name="user-profile"
    ),

    # ==========================
    # Documents
    # ==========================

    path(
        "documents/",
        DocumentListView.as_view(),
        name="document-list"
    ),

    path(
        "documents/<uuid:id>/",
        DocumentDetailView.as_view(),
        name="document-detail"
    ),

    path(
        "documents/<uuid:id>/review/",
        ReviewDocumentView.as_view(),
        name="document-review"
    ),

    # ==========================
    # Upload
    # ==========================

    path(
        "upload/",
        UploadDocumentView.as_view(),
        name="document-upload"
    ),

    # ==========================
    # AI Analyze
    # ==========================
    path(
        "ai/analyze/",
        AnalyzeAiView.as_view(),
        name="ai-analyze"
    ),

    # ==========================
    # Review Queue
    # ==========================

    path(
        "review-queue/",
        ReviewQueueView.as_view(),
        name="review-queue"
    ),

    # ==========================
    # Analytics
    # ==========================

    path(
        "stats/",
        StatisticsView.as_view(),
        name="stats"
    ),

    path(
        "stats/departments/",
        DepartmentStatisticsView.as_view(),
        name="department-stats"
    ),

    # ==========================
    # Reviewer Analytics
    # ==========================

    path(
        "stats/reviewers/",
        ReviewerStatisticsView.as_view(),
        name="reviewer-stats"
    ),

    path(
        "stats/reviewer-corrections/",
        ReviewerCorrectionView.as_view(),
        name="reviewer-corrections"
    ),

    # ==========================
    # Accuracy Analytics
    # ==========================

    path(
        "stats/accuracy/",
        AccuracyStatisticsView.as_view(),
        name="accuracy-stats"
    ),

    path(
        "stats/confusion-matrix/",
        ConfusionMatrixView.as_view(),
        name="confusion-matrix"
    ),
]