from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import User, Report, Location, Media
from .forms import CustomUserCreationForm, CustomUserChangeForm


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    add_form = CustomUserCreationForm
    form = CustomUserChangeForm

    list_display = ('id', 'roll_number', 'name', 'role', 'program', 'is_active', 'account_expiry')
    search_fields = ('roll_number', 'name')
    ordering = ('roll_number',)

    # Replaces BaseUserAdmin.fieldsets (which references 'username')
    fieldsets = (
        (None,               {'fields': ('roll_number', 'password')}),
        ('Personal Info',    {'fields': ('name',)}),
        ('Role & Program',   {'fields': ('role', 'program', 'account_expiry', 'has_logged_in')}),
        ('Permissions',      {'fields': ('is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions')}),
    )

    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('roll_number', 'role', 'program', 'password1', 'password2'),
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
    list_display = ('report', 'media_type', 'file')