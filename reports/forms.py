# reports/forms.py
from django import forms
from .models import User

class CustomUserCreationForm(forms.ModelForm):
    """
    Used in Django Admin to create users WITHOUT passwords,
    because Firebase Auth handles authentication.
    """
    class Meta:
        model = User
        fields = ('roll_number', 'name', 'role', 'program', 'account_expiry')


class CustomUserChangeForm(forms.ModelForm):
    """
    Used in Django Admin to edit users WITHOUT touching password fields.
    """
    class Meta:
        model = User
        fields = (
            'roll_number',
            'name',
            'role',
            'program',
            'account_expiry',
            'is_active',
            'is_staff',
            'is_superuser',
        )
