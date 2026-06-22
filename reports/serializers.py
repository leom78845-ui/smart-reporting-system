# reports/serializers.py

from rest_framework import serializers
from .models import User, Report, Location, Media

# ==============================================================================
# User Serializer (Admin Panel + Login)
# ==============================================================================

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = [
            'id',
            'roll_number',
            'name',
            'role',
            'program',
            'account_expiry',
            'is_active',
            'is_staff',
            'fcm_token',   # ⭐ Push notifications
        ]
        read_only_fields = ['id', 'account_expiry', 'is_active', 'is_staff']


# ==============================================================================
# Location Serializer
# ==============================================================================

class LocationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Location
        fields = ['latitude', 'longitude', 'address']


# ==============================================================================
# Media Serializer
# ==============================================================================

class MediaSerializer(serializers.ModelSerializer):
    class Meta:
        model = Media
        fields = ['id', 'file_url', 'media_type']


# ==============================================================================
# Report Serializer
# ==============================================================================

class ReportSerializer(serializers.ModelSerializer):
    # Nested serializers for location and media
    location = LocationSerializer(read_only=True)
    media = MediaSerializer(many=True, read_only=True)

    # Expose student roll number for admin dashboards
    student_roll_number = serializers.CharField(
        source='student.roll_number',
        read_only=True
    )

    class Meta:
        model = Report
        fields = [
            'id',
            'student_roll_number',
            'title',
            'description',
            'status',
            'submitted_at',
            'updated_at',
            'location',
            'media',
        ]
        read_only_fields = [
            'status',
            'submitted_at',
            'updated_at',
            'location',
            'media',
        ]

    def create(self, validated_data):
        """
        Custom create method to attach Location if lat/lng provided in request.
        """
        request = self.context.get('request')
        lat = request.data.get('latitude')
        lng = request.data.get('longitude')
        addr = request.data.get('address')

        report = Report.objects.create(**validated_data)

        if lat and lng:
            Location.objects.create(
                report=report,
                latitude=lat,
                longitude=lng,
                address=addr
            )

        return report
