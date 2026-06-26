import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      debugPrint('LOGIN_DEBUG: Auto-login triggered in SplashScreen');
      try {
        await ref.read(authProvider.notifier).login('admin', 'AdminPassword123!');
        debugPrint('LOGIN_DEBUG: Auto-login succeeded');
      } catch (e) {
        debugPrint('LOGIN_DEBUG: Auto-login failed: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Glowing Logo Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.08),
                border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGlow.withOpacity(0.2),
                    blurRadius: 40,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: const Text(
                '⚡',
                style: TextStyle(fontSize: 48),
              ),
            )
            .animate()
            .scale(duration: 800.ms, curve: Curves.easeOutBack)
            .fadeIn(duration: 800.ms),
            
            const SizedBox(height: 24),
            
            // App Title
            Text(
              'AssignHub',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.0,
              ),
            )
            .animate()
            .fadeIn(delay: 200.ms, duration: 600.ms)
            .slideY(begin: 0.2, end: 0.0),
            
            const SizedBox(height: 8),
            
            // Subtitle
            Text(
              'EdTech Operations Reimagined',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 0.2,
              ),
            )
            .animate()
            .fadeIn(delay: 450.ms, duration: 600.ms)
            .slideY(begin: 0.2, end: 0.0),
            
            const SizedBox(height: 48),
            
            // Premium Mini Loader
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary.withOpacity(0.8)),
              ),
            )
            .animate()
            .fadeIn(delay: 800.ms),
          ],
        ),
      ),
    );
  }
}
