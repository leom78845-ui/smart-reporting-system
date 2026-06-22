# reports/media_api.py
import os
import uuid
from django.conf import settings
from django.core.files.storage import FileSystemStorage
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from .permissions import IsStudentRole


class UploadMediaAPI(APIView):
    """
    Accepts raw file uploads, saves them locally to Django MEDIA_ROOT,
    and returns the absolute local server URL.
    """

    permission_classes = [IsAuthenticated, IsStudentRole]

    def post(self, request):
        file_obj = request.FILES.get('file')
        if not file_obj:
            return Response({"error": "No file uploaded"}, status=status.HTTP_400_BAD_REQUEST)

        # Ensure target media directory exists
        os.makedirs(settings.MEDIA_ROOT, exist_ok=True)

        # Generate unique filename preserving extension
        ext = os.path.splitext(file_obj.name)[1]
        filename = f"{uuid.uuid4()}{ext}"

        # Save to filesystem
        fs = FileSystemStorage(location=settings.MEDIA_ROOT, base_url=settings.MEDIA_URL)
        saved_name = fs.save(filename, file_obj)
        file_url = request.build_absolute_uri(fs.url(saved_name))

        return Response({
            "message": "File uploaded successfully",
            "media_url": file_url
        }, status=status.HTTP_200_OK)

