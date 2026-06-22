# reports/dashboard_api.py
from rest_framework.views import APIView
from rest_framework.response import Response
from django.utils.timezone import now, timedelta

from .models import Report, User
from rest_framework.permissions import IsAuthenticated
from .permissions import IsAdminRole


class AdminDashboardAPI(APIView):
    """
    Returns analytics for the admin dashboard.
    Supports:
    - Total reports
    - Reports by status
    - Reports by program (BS/MS)
    - Reports today / this week / this month
    - Optional filters: ?status=resolved&days=7
    """

    permission_classes = [IsAuthenticated, IsAdminRole]

    def get(self, request):
        status_filter = request.GET.get("status")
        days = request.GET.get("days")

        reports = Report.objects.all()

        # Optional status filter
        if status_filter:
            reports = reports.filter(status=status_filter)

        # Optional last X days filter
        if days:
            try:
                days = int(days)
                since = now() - timedelta(days=days)
                reports = reports.filter(submitted_at__gte=since)
            except:
                pass

        # Basic counts
        total_reports = reports.count()
        pending = reports.filter(status="pending").count()
        reviewing = reports.filter(status="reviewing").count()
        resolved = reports.filter(status="resolved").count()

        # Program-based counts
        bs_students = User.objects.filter(program="bs").count()
        ms_students = User.objects.filter(program="ms").count()

        # Time-based analytics
        today = now().date()
        week_start = today - timedelta(days=today.weekday())
        month_start = today.replace(day=1)

        reports_today = reports.filter(submitted_at__date=today).count()
        reports_this_week = reports.filter(submitted_at__date__gte=week_start).count()
        reports_this_month = reports.filter(submitted_at__date__gte=month_start).count()

        return Response({
            "total_reports": total_reports,
            "status_counts": {
                "pending": pending,
                "reviewing": reviewing,
                "resolved": resolved,
            },
            "program_counts": {
                "bs_students": bs_students,
                "ms_students": ms_students,
            },
            "time_based": {
                "today": reports_today,
                "this_week": reports_this_week,
                "this_month": reports_this_month,
            }
        })
