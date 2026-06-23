# reports/notification_api.py
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from .models import User
from rest_framework.permissions import IsAuthenticated
from .permissions import IsStudentRole


class RegisterFCMTokenAPI(APIView):
    """
    Saves the student's FCM device token so Django can send push notifications.
    """

    permission_classes = [IsAuthenticated, IsStudentRole]

    def post(self, request):
        fcm_token = request.data.get("fcm_token")

        if not fcm_token:
            return Response({"error": "fcm_token is required"}, status=status.HTTP_400_BAD_REQUEST)

        # JWT Authentication sets request.user
        user = request.user

        # Save token
        user.fcm_token = fcm_token
        user.save(update_fields=["fcm_token"])

        return Response({"message": "FCM token registered successfully"}, status=status.HTTP_200_OK)
