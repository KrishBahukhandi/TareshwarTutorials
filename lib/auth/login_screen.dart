import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppTheme.gray50,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppTheme.gray200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo and Header
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.school_rounded,
                            color: AppTheme.primaryBlue,
                            size: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'Welcome back',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.gray900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sign in to your EduTech account',
                              style: TextStyle(
                                fontSize: 15,
                                color: AppTheme.gray600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Email Input
                      Text(
                        'Email',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.gray700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'Enter your email',
                          prefixIcon: Icon(Icons.email_outlined, size: 20),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Password Input
                      Text(
                        'Password',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.gray700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          prefixIcon: Icon(Icons.lock_outline, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),

                      // Error Message
                      if (authState.error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.errorLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, 
                                color: AppTheme.error, 
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  authState.error!,
                                  style: TextStyle(
                                    color: AppTheme.error,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: authState.isLoading
                              ? null
                              : () async {
                                  await ref
                                      .read(authControllerProvider.notifier)
                                      .signIn(
                                        email: _emailController.text.trim(),
                                        password: _passwordController.text,
                                      );
                                },
                          child: authState.isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Sign in',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: AppTheme.gray300)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'or',
                              style: TextStyle(
                                color: AppTheme.gray500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: AppTheme.gray300)),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Quick Login Buttons
                      _QuickLoginButton(
                        label: 'Admin',
                        email: 'admin@edutech.test',
                        password: 'ChangeMe123!',
                        icon: Icons.admin_panel_settings_outlined,
                        color: AppTheme.primaryBlue,
                        onTap: () {
                          _emailController.text = 'admin@edutech.test';
                          _passwordController.text = 'ChangeMe123!';
                        },
                      ),
                      const SizedBox(height: 8),
                      _QuickLoginButton(
                        label: 'Teacher',
                        email: 'teacher@edutech.test',
                        password: 'ChangeMe123!',
                        icon: Icons.person_outline,
                        color: AppTheme.success,
                        onTap: () {
                          _emailController.text = 'teacher@edutech.test';
                          _passwordController.text = 'ChangeMe123!';
                        },
                      ),
                      const SizedBox(height: 8),
                      _QuickLoginButton(
                        label: 'Student',
                        email: 'student@edutech.test',
                        password: 'ChangeMe123!',
                        icon: Icons.school_outlined,
                        color: const Color(0xFF8B5CF6),
                        onTap: () {
                          _emailController.text = 'student@edutech.test';
                          _passwordController.text = 'ChangeMe123!';
                        },
                      ),

                      const SizedBox(height: 24),

                      // Sign up link
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Don\'t have an account? ',
                              style: TextStyle(
                                color: AppTheme.gray600,
                                fontSize: 14,
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.go('/signup'),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Sign up',
                                style: TextStyle(
                                  color: AppTheme.primaryBlue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickLoginButton extends StatelessWidget {
  const _QuickLoginButton({
    required this.label,
    required this.email,
    required this.password,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String email;
  final String password;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(12),
        side: BorderSide(color: AppTheme.gray300),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Text(
            'Login as $label',
            style: TextStyle(
              color: AppTheme.gray700,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
