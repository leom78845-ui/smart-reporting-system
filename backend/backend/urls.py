from django.contrib import admin
from django.urls import path, include

from django.conf import settings
from django.conf.urls.static import static


urlpatterns = [

    # admin panel
    path('admin/', admin.site.urls),

    # API routes
    path('api/', include('reports.urls')),

]

# media files support
urlpatterns += static(
    settings.MEDIA_URL,
    document_root=settings.MEDIA_ROOT
)