# reports/api.py
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from rest_framework.permissions import IsAuthenticated
from .models import User
from .permissions import IsAdminRole


class CreateStudentAPI(APIView):
    """
    Admin creates a single student user.
    Expected payload:
    {
        "roll_number": "k21-123",
        "name": "John Doe",
        "program": "bs" or "ms"
    }
    """

    permission_classes = [IsAuthenticated, IsAdminRole]

    def post(self, request):
        roll_number = request.data.get("roll_number")
        name = request.data.get("name", "")
        program = request.data.get("program", "bs")
        password = request.data.get("password") or "HU-Student123"

        if not roll_number:
            return Response({"error": "roll_number is required"}, status=status.HTTP_400_BAD_REQUEST)

        if program not in ["bs", "ms"]:
            return Response({"error": "program must be 'bs' or 'ms'"}, status=status.HTTP_400_BAD_REQUEST)

        # Check if already exists
        if User.objects.filter(roll_number=roll_number).exists():
            return Response({"error": "User with this roll number already exists"}, status=status.HTTP_400_BAD_REQUEST)

        # Create user
        user = User.objects.create_user(
            roll_number=roll_number,
            password=password,
            name=name,
            role="student",
            program=program,
        )

        # Firebase account auto-created in model.save()

        return Response({
            "message": "Student created successfully",
            "user": {
                "roll_number": user.roll_number,
                "name": user.name,
                "program": user.program,
            }
        }, status=status.HTTP_201_CREATED)
