from django.urls import path

from .views import StudentApprovalView, StudentLoginView, StudentListView, StudentRegistrationView

urlpatterns = [
    path('register/', StudentRegistrationView.as_view(), name='student-register'),
    path('login/', StudentLoginView.as_view(), name='student-login'),
    path('students/', StudentListView.as_view(), name='student-list'),
    path('students/<int:id>/approve/', StudentApprovalView.as_view(), name='student-approve'),
]
