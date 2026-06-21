from django.contrib.auth import get_user_model
from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.views import TokenObtainPairView

from .permissions import IsAdminUser
from .serializers import (
    CustomTokenObtainPairSerializer,
    StudentRegistrationSerializer,
)

User = get_user_model()


class StudentRegistrationView(generics.CreateAPIView):
    queryset = User.objects.all()
    permission_classes = []  # Publicly accessible for registration
    authentication_classes = []
    serializer_class = StudentRegistrationSerializer


class StudentLoginView(TokenObtainPairView):
    permission_classes = []
    authentication_classes = []
    serializer_class = CustomTokenObtainPairSerializer


class StudentListView(generics.ListAPIView):
    queryset = User.objects.filter(role='student')
    permission_classes = [IsAdminUser]
    serializer_class = StudentRegistrationSerializer


class StudentPendingListView(generics.ListAPIView):
    queryset = User.objects.filter(role='student', is_approved=False)
    permission_classes = [IsAdminUser]
    serializer_class = StudentRegistrationSerializer


class StudentApproveView(APIView):
    permission_classes = [IsAdminUser]

    def post(self, request, id):
        try:
            student = User.objects.get(id=id, role='student')
            student.is_approved = True
            student.is_active = True
            student.save()
            return Response(
                {"detail": f"Student {student.username} approved successfully."},
                status=status.HTTP_200_OK,
            )
        except User.DoesNotExist:
            return Response(
                {"detail": "Student not found."}, status=status.HTTP_404_NOT_FOUND
            )


class StudentRejectView(APIView):
    permission_classes = [IsAdminUser]

    def post(self, request, id):
        try:
            student = User.objects.get(id=id, role='student')
            student.is_approved = False
            student.is_active = False  # Deactivate student on reject
            student.save()
            return Response(
                {"detail": f"Student {student.username} rejected successfully."},
                status=status.HTTP_200_OK,
            )
        except User.DoesNotExist:
            return Response(
                {"detail": "Student not found."}, status=status.HTTP_404_NOT_FOUND
            )
