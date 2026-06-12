from django.urls import path
from . import views

urlpatterns = [
    # Auth
    path('login/', views.login_user, name='login'),
    # ADDED: URL for password change
    path('change-password/', views.change_password, name='change-password'),
    
    # Student
    path('reports/submit/', views.submit_report, name='submit-report'),
    path('my-reports/', views.my_reports, name='my-reports'),
    
    # Admin
    path('bulk-create/', views.bulk_create_users, name='bulk-create'),
    path('all-reports/', views.all_reports, name='all-reports'),
    path('reports/<int:id>/status/', views.update_report_status, name='update-status'),
]