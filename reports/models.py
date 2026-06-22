# reports/models.py

from django.db import models
from django.utils import timezone
from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin, BaseUserManager
from dateutil.relativedelta import relativedelta


# ============================
# User Manager
# ============================
class UserManager(BaseUserManager):
    def create_user(self, roll_number, password=None, **extra_fields):
        if not roll_number:
            raise ValueError("Users must have a roll number")

        user = self.model(roll_number=roll_number, **extra_fields)

        if password:
            user.set_password(password)
        else:
            user.set_unusable_password()

        user.save(using=self._db)
        return user

    def create_superuser(self, roll_number, password=None, **extra_fields):
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)

        if password is None:
            raise ValueError("Superuser must have a password")

        return self.create_user(roll_number, password=password, **extra_fields)


# ============================
# User Model
# ============================
class User(AbstractBaseUser, PermissionsMixin):
    ROLE_CHOICES = [('student', 'Student'), ('admin', 'Admin')]
    PROGRAM_CHOICES = [('bs', 'BS (4 years)'), ('ms', 'MS (2 years)')]

    roll_number = models.CharField(max_length=50, unique=True)
    name = models.CharField(max_length=100, blank=True)
    role = models.CharField(max_length=10, choices=ROLE_CHOICES, default='student')
    program = models.CharField(max_length=5, choices=PROGRAM_CHOICES, default='bs')
    account_expiry = models.DateField(null=True, blank=True)

    fcm_token = models.TextField(null=True, blank=True)

    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)

    USERNAME_FIELD = 'roll_number'
    REQUIRED_FIELDS = []

    objects = UserManager()

    def save(self, *args, **kwargs):
        is_new = self.pk is None
        super().save(*args, **kwargs)

        if is_new and self.role == 'student':
            years = 4 if self.program == 'bs' else 2
            self.account_expiry = (timezone.now() + relativedelta(years=years)).date()
            super().save(update_fields=['account_expiry'])

    def __str__(self):
        return f"{self.roll_number} ({self.name})"


# ============================
# Report Model
# ============================
class Report(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('reviewing', 'Reviewing'),
        ('resolved', 'Resolved'),
    ]

    student = models.ForeignKey(User, on_delete=models.CASCADE, related_name='submitted_reports')
    title = models.CharField(max_length=255)
    description = models.TextField()
    image_url = models.URLField(max_length=500, null=True, blank=True)

    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    submitted_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-submitted_at']

    def __str__(self):
        return f"{self.title} ({self.student.roll_number})"


# ============================
# Location Model
# ============================
class Location(models.Model):
    report = models.OneToOneField(Report, on_delete=models.CASCADE, related_name='location')
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=10, decimal_places=6)
    address = models.CharField(max_length=500, blank=True)

    def __str__(self):
        return f"Location for Report #{self.report.id}"


# ============================
# Media Model
# ============================
class Media(models.Model):
    MEDIA_TYPE_CHOICES = [('photo', 'Photo'), ('video', 'Video')]

    report = models.ForeignKey(Report, on_delete=models.CASCADE, related_name='media')
    file_url = models.URLField(max_length=500)
    media_type = models.CharField(max_length=10, choices=MEDIA_TYPE_CHOICES)

    def __str__(self):
        return f"{self.media_type} for Report #{self.report.id}"
