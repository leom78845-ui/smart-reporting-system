# reports/permissions.py
from rest_framework.permissions import BasePermission
from .models import User


# ==============================================================================
# Firebase Authentication Permission
# ==============================================================================

class FirebaseAuthenticated(BasePermission):
    """
    [DEPRECATED] Verifies Django authentication status.
    Transitioned from Firebase auth to Django Simple JWT.
    """

    def has_permission(self, request, view):
        return hasattr(request, "user") and request.user.is_authenticated



# ==============================================================================
# Role-Based Permissions
# ==============================================================================

class IsAdminRole(BasePermission):
    """
    Allows access only to admin users.
    """

    def has_permission(self, request, view):
        return hasattr(request, "user") and request.user.role == "admin"


class IsStudentRole(BasePermission):
    """
    Allows access only to student users whose accounts have not expired.
    """

    def has_permission(self, request, view):
        from django.utils import timezone
        
        if not hasattr(request, "user") or request.user.role != "student":
            return False
            
        if request.user.account_expiry and request.user.account_expiry < timezone.now().date():
            return False
            
        return True
