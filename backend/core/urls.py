from django.contrib import admin
from django.http import HttpResponse
from django.urls import path

from django.conf import settings
from django.conf.urls.static import static


def home(request):
    return HttpResponse(
        "Human-in-the-Loop AI Document Classifier"
    )


urlpatterns = [
    path("", home),
    path("admin/", admin.site.urls),
]

if settings.DEBUG:
    urlpatterns += static(
        settings.MEDIA_URL,
        document_root=settings.MEDIA_ROOT
    )