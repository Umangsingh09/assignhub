from rest_framework import viewsets

from accounts.permissions import IsAdminUser, IsApprovedStudentOrAdmin
from .models import Assignment
from .serializers import AssignmentSerializer


class AssignmentViewSet(viewsets.ModelViewSet):
    queryset = Assignment.objects.all().order_by("-created_at")
    serializer_class = AssignmentSerializer

    def get_permissions(self):
        if self.action in ["create", "update", "partial_update", "destroy"]:
            permission_classes = [IsAdminUser]
        else:
            permission_classes = [IsApprovedStudentOrAdmin]
        return [permission() for permission in permission_classes]
