# reports/heatmap_api.py
from rest_framework.views import APIView
from rest_framework.response import Response
from django.utils.timezone import now, timedelta

from .models import Report
from rest_framework.permissions import IsAuthenticated
from .permissions import IsAdminRole


class HeatmapAPI(APIView):
    """
    Returns all report locations for admin map view.
    Supports filters:
    - ?status=pending|reviewing|resolved
    - ?days=7  (last 7 days)
    """

    permission_classes = [IsAuthenticated, IsAdminRole]

    def get(self, request):
        status_filter = request.GET.get("status")
        days = request.GET.get("days")

        reports = Report.objects.all()

        # Filter by status
        if status_filter:
            reports = reports.filter(status=status_filter)

        # Filter by last X days
        if days:
            try:
                days = int(days)
                since = now() - timedelta(days=days)
                reports = reports.filter(submitted_at__gte=since)
            except:
                pass

        # Build response list
        points = []
        for r in reports:
            if hasattr(r, "location"):
                points.append({
                    "lat": float(r.location.latitude),
                    "lng": float(r.location.longitude),
                    "status": r.status,
                    "report_id": r.id,
                    "title": r.title,
                    "submitted_at": r.submitted_at,
                })

        return Response({
            "count": len(points),
            "points": points
        })
