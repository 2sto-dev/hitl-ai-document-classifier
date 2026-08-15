from django.contrib.auth.models import User
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError

from rest_framework import serializers


class RegisterSerializer(
    serializers.ModelSerializer
):

    password = serializers.CharField(
        write_only=True,
        min_length=8,
        trim_whitespace=False,
        style={"input_type": "password"}
    )

    email = serializers.EmailField(
        required=False,
        allow_blank=True
    )

    class Meta:

        model = User

        fields = [
            "username",
            "email",
            "password"
        ]

    def validate(self, attrs):
        candidate_user = User(
            username=attrs.get("username", ""),
            email=attrs.get("email", "")
        )

        try:
            validate_password(
                attrs["password"],
                user=candidate_user
            )
        except DjangoValidationError as error:
            raise serializers.ValidationError({
                "password": list(error.messages)
            }) from error

        return attrs

    def create(
        self,
        validated_data
    ):

        user = User.objects.create_user(

            username=validated_data[
                "username"
            ],

            email=validated_data.get(
                "email",
                ""
            ),

            password=validated_data[
                "password"
            ]
        )

        return user


class UserProfileSerializer(
    serializers.ModelSerializer
):

    password = serializers.CharField(
        write_only=True,
        required=False,
        min_length=8,
        trim_whitespace=False,
        style={"input_type": "password"}
    )

    class Meta:

        model = User

        fields = [
            "username",
            "email",
            "password"
        ]

    def validate_username(self, value):
        user = self.instance
        if User.objects.filter(username=value).exclude(pk=getattr(user, 'pk', None)).exists():
            raise serializers.ValidationError(
                "A user with that username already exists."
            )
        return value

    def validate_email(self, value):
        user = self.instance
        if value and User.objects.filter(email=value).exclude(pk=getattr(user, 'pk', None)).exists():
            raise serializers.ValidationError(
                "A user with that email already exists."
            )
        return value

    def validate(self, attrs):
        password = attrs.get("password")
        if not password:
            return attrs

        candidate_user = User(
            username=attrs.get("username", self.instance.username),
            email=attrs.get("email", self.instance.email)
        )

        try:
            validate_password(
                password,
                user=candidate_user
            )
        except DjangoValidationError as error:
            raise serializers.ValidationError({
                "password": list(error.messages)
            }) from error

        return attrs

    def update(self, instance, validated_data):
        password = validated_data.pop('password', None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        if password:
            instance.set_password(password)
        instance.save()
        return instance
