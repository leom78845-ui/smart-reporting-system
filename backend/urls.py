# backend/urls.py

from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

# ✅ Only import what exists
from reports.auth_api import RollNumberLoginAPI, me

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('reports.urls')),

    # Authentication routes
    path('login/', RollNumberLoginAPI.as_view(), name='roll-login'),
    path('auth/me/', me, name='me'),
]

if settings.DEBUG:
    urlpatterns += static(
        settings.MEDIA_URL,
        document_root=settings.MEDIA_ROOT
    )
