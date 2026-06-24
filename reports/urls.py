# reports/urls.py

from django.urls import path

from . import views
from .api import CreateStudentAPI
from .auth_api import RollNumberLoginAPI, me, ChangePasswordAPI, UpdateProfileAPI

from .sync_api import SyncReportsAPI
from .dashboard_api import AdminDashboardAPI
from .media_api import UploadMediaAPI
from .heatmap_api import HeatmapAPI
from .notification_api import RegisterFCMTokenAPI

urlpatterns = [
    # ============================
    # Student Features
    # ============================
    path('reports/submit/', views.submit_report, name='submit-report'),
    path('my-reports/', views.my_reports, name='my-reports'),

    # ============================
    # Admin Features
    # ============================
    path('bulk-create/', views.bulk_create_users, name='bulk-create'),
    path('all-reports/', views.all_reports, name='all-reports'),
    path('reports/<int:id>/status/', views.update_report_status, name='update-status'),
    path('reports/<int:report_id>/delete/', views.delete_report, name='delete-report'),

    # ============================
    # Student Creation API
    # ============================
    path('create-student/', CreateStudentAPI.as_view(), name='create-student'),

    # ============================
    # Roll Number Login API
    # ============================
    path('login/', RollNumberLoginAPI.as_view(), name='roll-login'),
    path('auth/me/', me, name='me'),
    path('auth/change-password/', ChangePasswordAPI.as_view(), name='change-password'),
    path('auth/update-profile/', UpdateProfileAPI.as_view(), name='update-profile'),


    # ============================
    # Other APIs
    # ============================
    path('sync-reports/', SyncReportsAPI.as_view(), name='sync-reports'),
    path('dashboard/', AdminDashboardAPI.as_view(), name='admin-dashboard'),
    path('upload-media/', UploadMediaAPI.as_view(), name='upload-media'),
    path('heatmap/', HeatmapAPI.as_view(), name='admin-heatmap'),
    path('register-fcm/', RegisterFCMTokenAPI.as_view(), name='register-fcm'),
]
