from rest_framework import serializers

from .models import Submission


class SubmissionSerializer(serializers.ModelSerializer):
    student_username = serializers.ReadOnlyField(source="student.username")
    assignment_title = serializers.ReadOnlyField(source="assignment.title")

    class Meta:
        model = Submission
        fields = [
            "id",
            "assignment",
            "assignment_title",
            "student",
            "student_username",
            "file_url",
            "text_submission",
            "submitted_at",
            "status",
            "is_late",
        ]
        read_only_fields = ["student", "submitted_at", "is_late"]

    def validate(self, attrs):
        request = self.context.get("request")
        if request and request.user:
            student = request.user
            # Ensure the user is an approved student or admin
            if student.role == "student" and not student.is_approved:
                raise serializers.ValidationError(
                    "Only approved students can make submissions."
                )

            # Avoid duplicate submissions for students
            assignment = attrs.get("assignment")
            if student.role == "student":
                if Submission.objects.filter(
                    assignment=assignment, student=student
                ).exists():
                    raise serializers.ValidationError(
                        "You have already submitted for this assignment."
                    )
        return attrs

    def create(self, validated_data):
        request = self.context.get("request")
        if request and request.user:
            # Students can only submit for themselves
            if request.user.role == "student":
                validated_data["student"] = request.user
            else:
                # Admins can submit for a student (if provided in validated_data),
                # but if student is not set (e.g. read-only field), default to admin
                if "student" not in validated_data:
                    validated_data["student"] = request.user
        return super().create(validated_data)
