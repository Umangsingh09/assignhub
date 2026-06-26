# Login Trace Report

## Trace log

### Flutter runtime trace
- LOGIN_DEBUG: Login button pressed
- LOGIN_DEBUG: Validation passed: true
- LOGIN_DEBUG: Form validation succeeded. Username: "admin"
- LOGIN_DEBUG: Password length: 20
- LOGIN_DEBUG: Invoking authProvider.notifier.login...
- LOGIN_DEBUG: AuthNotifier.login entered for username: admin
- LOGIN_DEBUG: Dio POST request url: http://127.0.0.1:8000/api/accounts/login/
- LOGIN_DEBUG: Dio POST request headers: {}
- LOGIN_DEBUG: Dio POST request body: {username: admin, password: AdminPassword123!}
- LOGIN_DEBUG: Dio response received. Status: 200
- LOGIN_DEBUG: Dio response headers: {content-length: [683], content-type: [application/json]}
- LOGIN_DEBUG: Dio response data: {refresh: ..., access: ..., role: admin, is_approved: true, roll_number: null}
- LOGIN_DEBUG: Saving tokens and user role: admin, approved: true
- LOGIN_DEBUG: Save completed successfully
- LOGIN_DEBUG: State updated to: AuthStatus.authenticated

### Backend verification
- The Django endpoint accepted the POST at /api/accounts/login/ and returned JWT tokens.

## Root cause
The login flow was previously blocked before the request reached Django because the browser was sending a cross-origin request from http://127.0.0.1:3000 to the Django API and the backend CORS allow-list did not include the Flutter origin. This caused the preflight request to fail and no POST reached Django.

## File modified
- backend/config/settings/base.py
- frontend_flutter/lib/features/auth/screens/login_screen.dart
- frontend_flutter/lib/features/auth/providers/auth_provider.dart

## Fix applied
- Added the Flutter web origin http://127.0.0.1:3000 (and localhost:3000) to Django CORS settings.
- Added explicit debugPrint trace points to the login screen and auth provider to verify each stage of the flow.
- Logged the Dio request URL, headers, body, response, and exception details for login requests.

## Final verification
- Chrome Network now shows the POST request to /api/accounts/login/ completing successfully.
- Django accepted the request and returned a 200 response with JWT tokens.
- A direct backend verification request returned access and refresh tokens.
