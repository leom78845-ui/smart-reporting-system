from django.contrib.auth.forms import UserCreationForm, UserChangeForm
from .models import User

class CustomUserCreationForm(UserCreationForm):
    class Meta:
        model = User
        fields = ('roll_number', 'role', 'program')

class CustomUserChangeForm(UserChangeForm):
    class Meta:
        model = User
        fields = ('roll_number', 'name', 'role', 'program', 'is_active', 'is_staff')