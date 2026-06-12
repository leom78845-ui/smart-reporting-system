from django.contrib.auth.backends import ModelBackend
from django.contrib.auth import get_user_model

class RollNumberBackend(ModelBackend):
    # Change 'request' to 'request=None' to make it optional
    def authenticate(self, request=None, roll_number=None, password=None, **kwargs):
        UserModel = get_user_model()
        try:
            user = UserModel.objects.get(roll_number=roll_number)
        except UserModel.DoesNotExist:
            return None
        
        # Verify password and active status
        if user.check_password(password) and self.user_can_authenticate(user):
            return user
        return None