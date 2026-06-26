import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/onboarding_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/pending_screen.dart';
import '../features/student/screens/student_dashboard_screen.dart';
import '../features/admin/screens/admin_dashboard_screen.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authProvider, (_, __) {
      debugPrint('LOGIN_DEBUG: authProvider changed, notifying router listeners');
      notifyListeners();
    });
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    refreshListenable: notifier,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/pending',
        builder: (context, state) => const PendingScreen(),
      ),
      GoRoute(
        path: '/student',
        builder: (context, state) => const StudentDashboardScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
    ],
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      
      final isSplash = state.matchedLocation == '/splash';
      final isOnboarding = state.matchedLocation == '/onboarding';
      final isLogin = state.matchedLocation == '/login';
      final isRegister = state.matchedLocation == '/register';
      final isPending = state.matchedLocation == '/pending';

      debugPrint('LOGIN_DEBUG: router redirect callback. location: ${state.matchedLocation}, authStatus: ${auth.status}, role: ${auth.role}');

      // 1. Loading State -> stay on splash
      if (auth.status == AuthStatus.loading) {
        debugPrint('LOGIN_DEBUG: Redirect AuthStatus.loading. redirecting to splash if not already there');
        return isSplash ? null : '/splash';
      }

      // 2. Unauthenticated -> Login, Register, or Onboarding only
      if (auth.status == AuthStatus.unauthenticated) {
        debugPrint('LOGIN_DEBUG: Redirect AuthStatus.unauthenticated. login/register/onboarding allowed.');
        if (isLogin || isRegister || isOnboarding) return null;
        debugPrint('LOGIN_DEBUG: Redirecting unauthenticated user from ${state.matchedLocation} to /login');
        return '/login';
      }

      // 3. Pending Approval -> force Pending Screen
      if (auth.status == AuthStatus.pendingApproval) {
        debugPrint('LOGIN_DEBUG: Redirect AuthStatus.pendingApproval. redirecting to /pending if not already there');
        return isPending ? null : '/pending';
      }

      // 4. Authenticated -> redirect away from login/register/splash/pending
      if (auth.status == AuthStatus.authenticated) {
        debugPrint('LOGIN_DEBUG: Redirect AuthStatus.authenticated.');
        if (isLogin || isRegister || isSplash || isPending || isOnboarding) {
          final target = auth.role == 'admin' ? '/admin' : '/student';
          debugPrint('LOGIN_DEBUG: Authenticated user at login/register/splash/pending. Redirecting to: $target');
          return target;
        }
        
        // RBAC Enforcement: prevent students accessing admin and vice versa
        if (auth.role == 'student' && state.matchedLocation.startsWith('/admin')) {
          debugPrint('LOGIN_DEBUG: Student tried to access admin. Redirecting to /student');
          return '/student';
        }
        if (auth.role == 'admin' && state.matchedLocation.startsWith('/student')) {
          debugPrint('LOGIN_DEBUG: Admin tried to access student. Redirecting to /admin');
          return '/admin';
        }
      }

      debugPrint('LOGIN_DEBUG: Redirect callback returning null (stay on current page)');
      return null;
    },
  );
});
