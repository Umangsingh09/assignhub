from rest_framework import permissions


class IsAdminUser(permissions.BasePermission):
    """
    Allows access only to admin users.
    """
    def has_permission(self, request, view):
        return bool(
            request.user and 
            request.user.is_authenticated and 
            (request.user.role == 'admin' or request.user.is_superuser)
        )


class IsApprovedStudentOrAdmin(permissions.BasePermission):
    """
    Allows access only to approved students and admins.
    """
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        
        # Admins always have access
        if request.user.role == 'admin' or request.user.is_superuser:
            return True
            
        # Students must be approved
        return request.user.role == 'student' and request.user.is_approved
