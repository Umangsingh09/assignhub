import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    debugPrint('LOGIN_DEBUG: Login button pressed');
    if (_formKey.currentState == null) {
      debugPrint('LOGIN_DEBUG: _formKey.currentState is null!');
    }
    final validationPassed = _formKey.currentState?.validate() ?? false;
    debugPrint('LOGIN_DEBUG: Validation passed: $validationPassed');
    if (!validationPassed) {
      debugPrint('LOGIN_DEBUG: Form validation failed');
      return;
    }
    
    debugPrint('LOGIN_DEBUG: Form validation succeeded. Username: "${_usernameController.text.trim()}"');
    debugPrint('LOGIN_DEBUG: Password length: ${_passwordController.text.length}');

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('LOGIN_DEBUG: Invoking authProvider.notifier.login...');
      await ref.read(authProvider.notifier).login(
        _usernameController.text.trim(),
        _passwordController.text,
      );
      debugPrint('LOGIN_DEBUG: authProvider.notifier.login completed successfully');
      // GoRouter redirect will automatically handle routing based on role/approval
    } catch (e, stack) {
      debugPrint('LOGIN_DEBUG: Exception caught in _handleLogin: $e');
      debugPrint('LOGIN_DEBUG: Stacktrace: $stack');
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withOpacity(0.04),
              ),
            ),
          ),

          // Main Layout
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isDesktop ? 950 : 440),
                child: isDesktop
                    ? Row(
                        children: [
                          // Left Side Panel: Premium branding
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 48.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: const Text(
                                      '⚡ EDTECH 2.0',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Manage assignments and submissions with Linear-speed.',
                                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                      fontSize: 38,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'AssignHub connects students and admins with automated grading states, direct Supabase storage attachments, and high-fidelity dashboard metrics.',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontSize: 15,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // Right Side Panel: Login Card
                          Expanded(
                            child: _buildLoginCard(),
                          ),
                        ],
                      )
                    : _buildLoginCard(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard() {
    return GlassCard(
      padding: const EdgeInsets.all(32.0),
      borderRadius: 24,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sign In',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontSize: 28,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Enter your credentials to enter your workspace',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.error, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Username input
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: 'e.g. johndoe',
                prefixIcon: Icon(Icons.alternate_email, size: 18, color: AppColors.textSecondary),
              ),
              validator: (val) => val == null || val.isEmpty ? 'Username required' : null,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),

            // Password input
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: '••••••••',
                prefixIcon: Icon(Icons.lock_outline, size: 18, color: AppColors.textSecondary),
              ),
              validator: (val) => val == null || val.isEmpty ? 'Password required' : null,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Sign In'),
              ),
            ),
            const SizedBox(height: 24),

            // Link to Register
            Center(
              child: TextButton(
                onPressed: () => context.go('/register'),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                    children: const [
                      TextSpan(text: 'Don\'t have an account? '),
                      TextSpan(
                        text: 'Register here',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scaleY(begin: 0.95, end: 1.0);
  }
}
