import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../providers/auth_provider.dart';

class PendingScreen extends ConsumerStatefulWidget {
  const PendingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PendingScreen> createState() => _PendingScreenState();
}

class _PendingScreenState extends ConsumerState<PendingScreen> {
  bool _isChecking = false;

  Future<void> _checkStatus() async {
    setState(() {
      _isChecking = true;
    });
    
    // Call refresh status which checks JWT token claims for approval update
    await ref.read(authProvider.notifier).refreshStatus();

    if (mounted) {
      setState(() {
        _isChecking = false;
      });
      
      // If still pending, show a brief snackbar
      final currentAuth = ref.read(authProvider);
      if (currentAuth.status == AuthStatus.pendingApproval) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account is still pending admin approval.'),
            backgroundColor: AppColors.warning,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
              borderRadius: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Clock Icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.warning.withOpacity(0.08),
                      border: Border.all(color: AppColors.warning.withOpacity(0.3), width: 1.5),
                    ),
                    child: const Text(
                      '⏳',
                      style: TextStyle(fontSize: 48),
                    ),
                  )
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05), duration: 2.seconds, curve: Curves.easeInOut),
                  
                  const SizedBox(height: 32),
                  
                  Text(
                    'Approval Pending',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontSize: 28,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    'Welcome, @${authState.username ?? "Student"}! Your account was successfully created. Please wait for an administrator to review and approve your registration.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 14.5,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Check Status Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isChecking ? null : _checkStatus,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: _isChecking
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Refresh Status'),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Sign Out Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => ref.read(authProvider.notifier).logout(),
                      child: const Text('Sign Out'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
