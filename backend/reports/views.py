from django.db import transaction
from django.contrib.auth import authenticate
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken
from .models import User, Report, Location
from .permissions import IsAdminRole, IsStudentRole

# --- Auth ---
@api_view(['POST'])
def register(request):
    return Response({"message": "Registration functionality coming soon."})

@api_view(['POST'])
@permission_classes([AllowAny])
def login_user(request):
    roll_number = request.data.get('roll_number')
    password = request.data.get('password')
    
    user = authenticate(roll_number=roll_number, password=password)
    
    if user is not None:
        refresh = RefreshToken.for_user(user)
        return Response({
            'access': str(refresh.access_token),
            'refresh': str(refresh),
            'roll_number': user.roll_number,
            'role': user.role,
            'is_first_login': getattr(user, 'is_first_login', False) 
        }, status=status.HTTP_200_OK)
    
    return Response(
        {"detail": "Invalid credentials"}, 
        status=status.HTTP_401_UNAUTHORIZED
    )

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def change_password(request):
    user = request.user
    old_password = request.data.get('old_password')
    new_password = request.data.get('new_password')
    
    if not user.check_password(old_password):
        return Response({"detail": "Incorrect old password"}, status=status.HTTP_400_BAD_REQUEST)
        
    user.set_password(new_password)
    user.is_first_login = False
    user.save()
    
    return Response({"message": "Password updated successfully"}, status=status.HTTP_200_OK)

# --- Student Features ---
@api_view(['POST'])
@permission_classes([IsStudentRole])
def submit_report(request):
    try:
        with transaction.atomic():
            report = Report.objects.create(
                student=request.user,
                title=request.data.get('title'),
                description=request.data.get('description'),
                image=request.FILES.get('file') 
            )
            Location.objects.create(
                report=report,
                latitude=request.data.get('latitude'),
                longitude=request.data.get('longitude')
            )
            return Response({"status": "success"}, status=status.HTTP_201_CREATED)
    except Exception as e:
        return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
@permission_classes([IsStudentRole])
def my_reports(request):
    return Response({"message": "List of my reports."})

# --- Admin Features ---
@api_view(['POST'])
@permission_classes([IsAdminRole])
def bulk_create_users(request):
    data = request.data
    prefix = data.get('prefix')
    start = int(data.get('start', 0))
    end = int(data.get('end', 0))
    password = data.get('password')
    
    with transaction.atomic():
        for i in range(start, end + 1):
            r_num = f"{prefix}{i}"
            User.objects.create_user(roll_number=r_num, password=password, role='student')
            
    return Response({"message": "Batch creation successful."})

@api_view(['GET'])
@permission_classes([IsAdminRole])
def all_reports(request):
    return Response({"message": "List of all reports."})

@api_view(['PATCH'])
@permission_classes([IsAdminRole])
def update_report_status(request, id):
    return Response({"message": f"Status updated for report {id}."})