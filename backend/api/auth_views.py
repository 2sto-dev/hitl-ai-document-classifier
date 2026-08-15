from django.contrib.auth.models import User

from rest_framework import generics
from rest_framework.permissions import IsAuthenticated

from .auth_serializers import (
    RegisterSerializer,
    UserProfileSerializer,
)


class RegisterView(
    generics.CreateAPIView
):

    queryset = (
        User.objects.all()
    )

    serializer_class = (
        RegisterSerializer
    )


class UserProfileView(
    generics.RetrieveUpdateAPIView
):

    permission_classes = (
        IsAuthenticated,
    )

    serializer_class = (
        UserProfileSerializer
    )

    def get_object(self):
        return self.request.user