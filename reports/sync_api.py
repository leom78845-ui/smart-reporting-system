# reports/sync_api.py
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django.db import transaction

from .models import Report, Location
from .serializers import ReportSerializer
from rest_framework.permissions import IsAuthenticated
from .permissions import IsStudentRole


class SyncReportsAPI(APIView):
    """
    Accepts multiple offline reports and syncs them to the server.
    """

    permission_classes = [IsAuthenticated, IsStudentRole]

    def post(self, request):
        user = request.user  # JWT Authentication sets this
        reports_data = request.data.get("reports", [])

        if not isinstance(reports_data, list):
            return Response({"error": "reports must be a list"}, status=status.HTTP_400_BAD_REQUEST)

        synced_reports = []

        try:
            with transaction.atomic():
                for item in reports_data:
                    title = item.get("title")
                    description = item.get("description")
                    image_url = item.get("image_url")
                    latitude = item.get("latitude")
                    longitude = item.get("longitude")
                    address = item.get("address", "")

                    if not title or not description:
                        continue  # skip invalid entries

                    # Create report
                    report = Report.objects.create(
                        student=user,
                        title=title,
                        description=description,
                        image_url=image_url,
                    )

                    # Create location if provided
                    if latitude is not None and longitude is not None:
                        Location.objects.create(
                            report=report,
                            latitude=latitude,
                            longitude=longitude,
                            address=address,
                        )

                    synced_reports.append(report)

        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)

        serializer = ReportSerializer(synced_reports, many=True)
        return Response({"synced": serializer.data}, status=status.HTTP_201_CREATED)
