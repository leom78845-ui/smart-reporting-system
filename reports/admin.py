# reports/admin.py

from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import User, Report, Location, Media


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    model = User

    list_display = (
        'id',
        'roll_number',
        'name',
        'role',
        'program',
        'is_active',
        'is_staff',
        'is_superuser',
        'account_expiry',
    )

    ordering = ('roll_number',)

    # ✅ Removed firebase_uid (no longer exists)
    readonly_fields = ()

    fieldsets = (
        (None, {'fields': ('roll_number', 'password')}),
        ('Personal Info', {'fields': ('name',)}),
        ('Role & Program', {'fields': ('role', 'program', 'account_expiry')}),
        ('Permissions', {
            'fields': ('is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions')
        }),
    )

    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': (
                'roll_number',
                'name',
                'role',
                'program',
                'password1',
                'password2',
            ),
        }),
    )


@admin.register(Report)
class ReportAdmin(admin.ModelAdmin):
    list_display = ('title', 'student', 'status', 'submitted_at')
    list_filter = ('status',)
    search_fields = ('title', 'student__roll_number')


@admin.register(Location)
class LocationAdmin(admin.ModelAdmin):
    list_display = ('report', 'latitude', 'longitude', 'address')


@admin.register(Media)
class MediaAdmin(admin.ModelAdmin):
    list_display = ('report', 'media_type', 'file_url')
