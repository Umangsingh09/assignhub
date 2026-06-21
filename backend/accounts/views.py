from django.contrib.auth import get_user_model
from rest_framework import generics, permissions
from rest_framework_simplejwt.views import TokenObtainPairView

from .serializers import (
    ApprovalSerializer,
    CustomTokenObtainPairSerializer,
    StudentRegistrationSerializer,
)

User = get_user_model()


class StudentRegistrationView(generics.CreateAPIView):
    queryset = User.objects.all()
    permission_classes = [permissions.AllowAny]
    serializer_class = StudentRegistrationSerializer


class StudentLoginView(TokenObtainPairView):
    serializer_class = CustomTokenObtainPairSerializer


class StudentApprovalView(generics.UpdateAPIView):
    queryset = User.objects.filter(role='student')
    permission_classes = [permissions.IsAdminUser]
    serializer_class = ApprovalSerializer
    lookup_field = 'id'

    def patch(self, request, *args, **kwargs):
        return self.partial_update(request, *args, **kwargs)


class StudentListView(generics.ListAPIView):
    queryset = User.objects.filter(role='student')
    permission_classes = [permissions.IsAdminUser]
    serializer_class = StudentRegistrationSerializer
