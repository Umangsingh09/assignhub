from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from django.utils import timezone
from datetime import timedelta
import random
from assignments.models import Assignment
from submissions.models import Submission

User = get_user_model()

class Command(BaseCommand):
    help = "Seed AssignHub database with test data (1 admin, 5 approved students, 5 pending students, 10 assignments, 20 submissions)"

    def handle(self, *args, **options):
        self.stdout.write("Seeding data...")
        
        # 1. Admin
        admin, created = User.objects.get_or_create(
            username="admin",
            email="admin@assignhub.com",
            defaults={
                "role": "admin",
                "is_approved": True,
                "is_staff": True,
                "is_superuser": True
            }
        )
        if created or not admin.check_password("AdminPassword123!"):
            admin.set_password("AdminPassword123!")
            admin.save()
            self.stdout.write(self.style.SUCCESS("Admin user 'admin' created/updated."))

        # 2. Approved Students (5)
        approved_students = []
        for i in range(1, 6):
            username = f"student_app{i}"
            email = f"student_app{i}@example.com"
            roll_number = f"ROLL_APP_00{i}"
            student, created = User.objects.get_or_create(
                username=username,
                email=email,
                defaults={
                    "role": "student",
                    "is_approved": True,
                    "roll_number": roll_number
                }
            )
            if created or not student.check_password("StudentPassword123!"):
                student.set_password("StudentPassword123!")
                student.save()
            approved_students.append(student)
        self.stdout.write(self.style.SUCCESS("5 Approved students created/updated."))

        # 3. Pending Students (5)
        for i in range(1, 6):
            username = f"student_pend{i}"
            email = f"student_pend{i}@example.com"
            roll_number = f"ROLL_PEND_00{i}"
            student, created = User.objects.get_or_create(
                username=username,
                email=email,
                defaults={
                    "role": "student",
                    "is_approved": False,
                    "roll_number": roll_number
                }
            )
            if created or not student.check_password("StudentPassword123!"):
                student.set_password("StudentPassword123!")
                student.save()
        self.stdout.write(self.style.SUCCESS("5 Pending students created/updated."))

        # 4. Assignments (10)
        assignments = []
        topics = [
            ("Python Basics", "Introduction to variables, loops, and standard data types in Python.", -10),
            ("Django Models", "Designing a database schema using Django Object-Relational Mapping (ORM).", -7),
            ("REST API Design", "Building RESTful endpoints using Django REST Framework views and serializers.", -5),
            ("JWT Authentication", "Securing API endpoints using JSON Web Tokens (SimpleJWT).", -3),
            ("Supabase Storage Integration", "Uploading and serving files via Supabase Storage buckets.", -1),
            ("Docker Containers", "Containerizing a Django backend with PostgreSQL using Docker Compose.", 1),
            ("GitHub Actions CI/CD", "Automating tests and deployment pipelines using GitHub Actions.", 3),
            ("Database Optimization", "Analyzing queries, index optimization, and transaction pooler settings.", 5),
            ("Unit Testing with Mocking", "Writing unit and integration tests using pytest, mock, and factory_boy.", 7),
            ("Final Project Submission", "Complete backend service integration, API verification, and documentation.", 14)
        ]

        now = timezone.now()
        for idx, (title, desc, days_offset) in enumerate(topics, 1):
            deadline = now + timedelta(days=days_offset)
            assignment, created = Assignment.objects.get_or_create(
                title=title,
                defaults={
                    "description": desc,
                    "pdf_url": f"https://nlmofhlhbsnqftoiyoqh.supabase.co/storage/v1/object/public/assignments/assignment_{idx}.pdf",
                    "external_link": "https://github.com/Umangsingh09/assignhub" if idx % 2 == 0 else None,
                    "deadline": deadline,
                    "created_by": admin
                }
            )
            if not created:
                assignment.description = desc
                assignment.deadline = deadline
                assignment.pdf_url = f"https://nlmofhlhbsnqftoiyoqh.supabase.co/storage/v1/object/public/assignments/assignment_{idx}.pdf"
                assignment.external_link = "https://github.com/Umangsingh09/assignhub" if idx % 2 == 0 else None
                assignment.created_by = admin
                assignment.save()
            assignments.append(assignment)
        self.stdout.write(self.style.SUCCESS("10 Assignments created/updated."))

        # 5. Submissions (20)
        # Delete existing submissions to reset cleanly
        Submission.objects.all().delete()

        submission_count = 0
        status_options = ["graded", "pending", "graded"]
        
        # Let's create 4 submissions for each of the 5 approved students = 20 submissions
        for s_idx, student in enumerate(approved_students):
            for a_offset in range(4):
                assignment = assignments[(s_idx + a_offset) % 10]
                status = random.choice(status_options)
                
                sub = Submission(
                    assignment=assignment,
                    student=student,
                    file_url=f"https://nlmofhlhbsnqftoiyoqh.supabase.co/storage/v1/object/public/submissions/sub_{student.username}_{assignment.id}.pdf",
                    text_submission=f"Here is my solution for the assignment: {assignment.title}.",
                    status=status
                )
                sub.save()
                submission_count += 1
                
        self.stdout.write(self.style.SUCCESS(f"Seeded {submission_count} submissions successfully."))
