import re
from rest_framework import serializers
from .models import User, Report, Location, Media, OfflineReport


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)

    class Meta:
        model  = User
        fields = ['username', 'email', 'password', 'role', 'program']

    # #2 — validate email contains rollnumber.edu
    def validate_email(self, value):
        if not re.search(r'\d+.*\.edu', value, re.IGNORECASE):
            raise serializers.ValidationError(
                'Email must contain a roll number and end with .edu (e.g. k21-1234@nu.edu.pk)'
            )
        return value

    def create(self, validated_data):
        user = User.objects.create_user(**validated_data)
        # #3 — set expiry on creation
        user.set_expiry()
        user.save()
        return user


class LocationSerializer(serializers.ModelSerializer):
    class Meta:
        model  = Location
        fields = ['latitude', 'longitude', 'address']


class MediaSerializer(serializers.ModelSerializer):
    class Meta:
        model  = Media
        fields = ['id', 'file', 'media_type', 'uploaded_at']


class ReportSerializer(serializers.ModelSerializer):
    location         = LocationSerializer(read_only=True)
    media            = MediaSerializer(many=True, read_only=True)
    student_username = serializers.CharField(source='student.username', read_only=True)

    class Meta:
        model  = Report
        fields = [
            'id', 'student_username', 'title', 'description',
            'status', 'submitted_at', 'updated_at', 'location', 'media'
        ]
        read_only_fields = ['status', 'submitted_at', 'updated_at']


class OfflineReportSerializer(serializers.ModelSerializer):
    class Meta:
        model  = OfflineReport
        fields = ['id', 'title', 'description', 'latitude', 'longitude',
                  'address', 'file', 'media_type', 'captured_at', 'synced']
        read_only_fields = ['synced', 'captured_at']