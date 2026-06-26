import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _rollNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _rollNumberController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authProvider.notifier).register(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        rollNumber: _rollNumberController.text.trim(),
        password: _passwordController.text,
      );
      
      // Show success popup and route back to login
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please login.'),
            backgroundColor: AppColors.accent,
          ),
        );
        context.go('/login');
      }
    } catch (e) {
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -150,
            right: -100,
            child: Container(
              width: 450,
              height: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.04),
              ),
            ),
          ),

          // Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: GlassCard(
                  padding: const EdgeInsets.all(32.0),
                  borderRadius: 24,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Account',
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontSize: 28,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Register as a student. Admin approval is required.',
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

                        // Username Input
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            prefixIcon: Icon(Icons.alternate_email, size: 18, color: AppColors.textSecondary),
                          ),
                          validator: (val) => val == null || val.isEmpty ? 'Username required' : null,
                          enabled: !_isLoading,
                        ),
                        const SizedBox(height: 16),

                        // Name split inputs
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _firstNameController,
                                decoration: const InputDecoration(
                                  labelText: 'First Name',
                                ),
                                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                                enabled: !_isLoading,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _lastNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Last Name',
                                ),
                                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                                enabled: !_isLoading,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Email Input
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: Icon(Icons.mail_outline, size: 18, color: AppColors.textSecondary),
                          ),
                          validator: (val) => val == null || !val.contains('@') ? 'Valid email required' : null,
                          enabled: !_isLoading,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),

                        // Roll Number Input
                        TextFormField(
                          controller: _rollNumberController,
                          decoration: const InputDecoration(
                            labelText: 'Roll Number',
                            prefixIcon: Icon(Icons.badge_outlined, size: 18, color: AppColors.textSecondary),
                          ),
                          validator: (val) => val == null || val.isEmpty ? 'Roll number required' : null,
                          enabled: !_isLoading,
                        ),
                        const SizedBox(height: 16),

                        // Password Input
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline, size: 18, color: AppColors.textSecondary),
                          ),
                          validator: (val) => val == null || val.length < 8 ? 'Password must be at least 8 chars' : null,
                          enabled: !_isLoading,
                        ),
                        const SizedBox(height: 16),

                        // Confirm Password Input
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Confirm Password',
                            prefixIcon: Icon(Icons.lock_outline, size: 18, color: AppColors.textSecondary),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Please confirm password';
                            if (val != _passwordController.text) return 'Passwords do not match';
                            return null;
                          },
                          enabled: !_isLoading,
                        ),
                        const SizedBox(height: 24),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegister,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text('Register'),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Link to Login
                        Center(
                          child: TextButton(
                            onPressed: () => context.go('/login'),
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                                children: const [
                                  TextSpan(text: 'Already have an account? '),
                                  TextSpan(
                                    text: 'Sign in here',
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
