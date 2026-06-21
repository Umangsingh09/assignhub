from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import PermissionDenied
from rest_framework.response import Response

from accounts.permissions import IsApprovedStudentOrAdmin
from .models import Submission
from .serializers import SubmissionSerializer


class SubmissionViewSet(viewsets.ModelViewSet):
    serializer_class = SubmissionSerializer

    def get_permissions(self):
        # All actions require the user to be an approved student or admin
        return [IsApprovedStudentOrAdmin()]

    def get_queryset(self):
        user = self.request.user
        if not user or not user.is_authenticated:
            return Submission.objects.none()

        # Admin can view all submissions, with optional filter parameters
        if user.role == "admin" or user.is_superuser:
            queryset = Submission.objects.all()
            assignment_id = self.request.query_params.get("assignment")
            student_id = self.request.query_params.get("student")
            if assignment_id:
                queryset = queryset.filter(assignment_id=assignment_id)
            if student_id:
                queryset = queryset.filter(student_id=student_id)
            return queryset.order_by("-submitted_at")

        # Students can only view their own submissions
        return Submission.objects.filter(student=user).order_by("-submitted_at")

    def perform_update(self, serializer):
        # Only admin can update submissions (e.g., to change status to 'graded')
        user = self.request.user
        if not (user.role == "admin" or user.is_superuser):
            raise PermissionDenied(
                "Students are not allowed to update submissions."
            )
        serializer.save()

    def perform_destroy(self, instance):
        # Only admin can delete submissions
        user = self.request.user
        if not (user.role == "admin" or user.is_superuser):
            raise PermissionDenied(
                "Students are not allowed to delete submissions."
            )
        instance.delete()

    @action(detail=False, methods=["get"], url_path="pending")
    def pending(self, request):
        """
        Track pending submissions (status='pending').
        Admins see all pending; students see their own pending submissions.
        """
        queryset = self.get_queryset().filter(status="pending")
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)
