# reports/views.py

from django.db import transaction
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.decorators import api_view, permission_classes
from rest_framework import status, permissions

from .models import User, Report, Location
from .serializers import ReportSerializer
from .permissions import IsAdminRole, IsStudentRole


# ============================
# Helper: Get current user from JWT
# ============================
def get_user_from_request(request):
    user = getattr(request, "user", None)
    if user is None or not isinstance(user, User):
        return None
    return user


# ============================
# Student Features
# ============================

@api_view(['POST'])
@permission_classes([IsStudentRole])
def submit_report(request):
    """
    Student submits a report.
    """
    user = get_user_from_request(request)
    if user is None:
        return Response({"error": "User not found"}, status=status.HTTP_401_UNAUTHORIZED)

    title = request.data.get('title')
    description = request.data.get('description')
    image_url = request.data.get('media_url')
    latitude = request.data.get('latitude')
    longitude = request.data.get('longitude')
    address = request.data.get('address', '')

    if not title or not description:
        return Response({"error": "Title and description are required"}, status=status.HTTP_400_BAD_REQUEST)

    try:
        with transaction.atomic():
            report = Report.objects.create(
                student=user,
                title=title,
                description=description,
                image_url=image_url,
            )
            if latitude is not None and longitude is not None:
                Location.objects.create(
                    report=report,
                    latitude=latitude,
                    longitude=longitude,
                    address=address,
                )
            serializer = ReportSerializer(report)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
    except Exception as e:
        return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([IsStudentRole])
def my_reports(request):
    """
    Return all reports submitted by the logged-in student.
    """
    user = get_user_from_request(request)
    if user is None:
        return Response({"error": "User not found"}, status=status.HTTP_401_UNAUTHORIZED)

    reports = Report.objects.filter(student=user).order_by('-submitted_at')
    serializer = ReportSerializer(reports, many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)


# ============================
# Admin Features
# ============================

@api_view(['POST'])
@permission_classes([IsAdminRole])
def bulk_create_users(request):
    """
    Admin creates a batch of student users.
    """
    prefix = request.data.get('prefix')
    start_val = str(request.data.get('start', '0'))
    end_val = str(request.data.get('end', '0'))
    program = request.data.get('program', 'bs')
    password = request.data.get('password') or "HU-Student123"

    try:
        start = int(start_val)
        end = int(end_val)
    except (ValueError, TypeError):
        return Response({"error": "Start and end must be valid integers"}, status=status.HTTP_400_BAD_REQUEST)

    if not prefix or start <= 0 or end < start:
        return Response({"error": "Invalid prefix, start, or end range"}, status=status.HTTP_400_BAD_REQUEST)

    # Dynamically detect padding width from input string (e.g. "001" -> width 3)
    width = len(start_val)

    created = 0
    with transaction.atomic():
        for i in range(start, end + 1):
            roll_number = f"{prefix}{str(i).zfill(width)}"
            if not User.objects.filter(roll_number=roll_number).exists():
                User.objects.create_user(
                    roll_number=roll_number,
                    password=password,
                    role='student',
                    program=program,
                )
                created += 1

    return Response({"message": f"Batch creation successful. {created} users created."}, status=status.HTTP_201_CREATED)


@api_view(['GET'])
@permission_classes([IsAdminRole])
def all_reports(request):
    """
    Admin: list all reports.
    """
    reports = Report.objects.all().order_by('-submitted_at')
    serializer = ReportSerializer(reports, many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)


@api_view(['PATCH'])
@permission_classes([IsAdminRole])
def update_report_status(request, id):
    """
    Admin: update status of a report.
    """
    try:
        report = Report.objects.get(id=id)
    except Report.DoesNotExist:
        return Response({"error": "Report not found"}, status=status.HTTP_404_NOT_FOUND)

    new_status = request.data.get('status')
    valid_statuses = dict(Report.STATUS_CHOICES).keys()

    if new_status not in valid_statuses:
        return Response({"error": f"Invalid status. Valid options: {', '.join(valid_statuses)}"}, status=status.HTTP_400_BAD_REQUEST)

    report.status = new_status
    report.save()
    serializer = ReportSerializer(report)
    return Response(serializer.data, status=status.HTTP_200_OK)


# ============================
# Sync Offline Reports
# ============================

class SyncReportsView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        reports_data = request.data.get("reports", [])
        if not isinstance(reports_data, list):
            return Response({"error": "Reports must be provided as a list"}, status=status.HTTP_400_BAD_REQUEST)

        saved_reports = []
        errors = []

        for report_data in reports_data:
            serializer = ReportSerializer(data=report_data)
            if serializer.is_valid():
                report = serializer.save(student=request.user)
                saved_reports.append(ReportSerializer(report).data)
            else:
                errors.append(serializer.errors)

        return Response({"saved": saved_reports, "errors": errors, "count": len(saved_reports)}, status=status.HTTP_201_CREATED)
