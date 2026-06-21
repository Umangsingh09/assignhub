from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView

from accounts.permissions import IsAdminUser
from assignments.models import Assignment
from submissions.models import Submission

User = get_user_model()


class DashboardAnalyticsView(APIView):
    permission_classes = [IsAdminUser]

    def get(self, request):
        total_students = User.objects.filter(role="student").count()
        pending_approvals = User.objects.filter(
            role="student", is_approved=False
        ).count()
        approved_students = User.objects.filter(
            role="student", is_approved=True
        ).count()

        total_assignments = Assignment.objects.count()
        total_submissions = Submission.objects.count()
        late_submissions = Submission.objects.filter(is_late=True).count()

        # Completion percentage formula:
        # (Total Submissions / (Approved Students * Total Assignments)) * 100
        denominator = approved_students * total_assignments
        if denominator > 0:
            completion_percentage = round(
                (total_submissions / denominator) * 100, 2
            )
        else:
            completion_percentage = 0.0

        return Response(
            {
                "total_students": total_students,
                "pending_approvals": pending_approvals,
                "total_assignments": total_assignments,
                "total_submissions": total_submissions,
                "completion_percentage": completion_percentage,
                "late_submissions": late_submissions,
            },
            status=status.HTTP_200_OK,
        )
