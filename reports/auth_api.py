from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from django.contrib.auth import authenticate
from rest_framework.decorators import api_view
from rest_framework_simplejwt.tokens import RefreshToken
from .models import User


class RollNumberLoginAPI(APIView):
    """
    Authenticates a user by roll_number + password using Django's own
    password check. Returns JWT access/refresh tokens + user info.
    """
    permission_classes = [permissions.AllowAny]   # ✅ Open endpoint

    def post(self, request):
        roll_number = request.data.get("roll_number")
        password = request.data.get("password")

        if not roll_number or not password:
            return Response(
                {"error": "roll_number and password are required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user = authenticate(request, roll_number=roll_number, password=password)

        if user is None:
            return Response({"error": "Invalid credentials"}, status=status.HTTP_401_UNAUTHORIZED)

        if not user.is_active:
            return Response({"error": "Account is disabled"}, status=status.HTTP_403_FORBIDDEN)

        from django.utils import timezone
        if user.role == 'student' and user.account_expiry and user.account_expiry < timezone.now().date():
            return Response({"error": "Account has expired"}, status=status.HTTP_403_FORBIDDEN)

        # ✅ Generate JWT tokens
        refresh = RefreshToken.for_user(user)
        access = str(refresh.access_token)

        return Response({
            "message": "Login successful",
            "access": access,
            "refresh": str(refresh),
            "user": {
                "roll_number": user.roll_number,
                "name": user.name,
                "role": user.role,
                "program": user.program,
            }
        }, status=status.HTTP_200_OK)


@api_view(["GET"])
def me(request):
    """
    Returns the currently authenticated user's profile.
    """
    user = request.user
    if not user.is_authenticated:
        return Response({"error": "Not authenticated"}, status=status.HTTP_401_UNAUTHORIZED)

    return Response({
        "roll_number": user.roll_number,
        "name": user.name,
        "role": user.role,
        "program": user.program,
    })


class ChangePasswordAPI(APIView):
    """
    Allows authenticated users to change their password.
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        new_password = request.data.get("new_password")
        if not new_password or len(new_password) < 6:
            return Response(
                {"error": "Password must be at least 6 characters long"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user = request.user
        user.set_password(new_password)
        user.save()

        return Response({"message": "Password updated successfully"}, status=status.HTTP_200_OK)

