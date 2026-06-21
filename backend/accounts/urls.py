from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

from .views import (
    StudentApproveView,
    StudentListView,
    StudentLoginView,
    StudentPendingListView,
    StudentRegistrationView,
    StudentRejectView,
)

urlpatterns = [
    path("register/", StudentRegistrationView.as_view(), name="student-register"),
    path("login/", StudentLoginView.as_view(), name="student-login"),
    path("token/refresh/", TokenRefreshView.as_view(), name="token-refresh"),
    path("students/", StudentListView.as_view(), name="student-list"),
    path(
        "students/pending/",
        StudentPendingListView.as_view(),
        name="student-pending-list",
    ),
    path(
        "students/<int:id>/approve/",
        StudentApproveView.as_view(),
        name="student-approve",
    ),
    path(
        "students/<int:id>/reject/",
        StudentRejectView.as_view(),
        name="student-reject",
    ),
]
