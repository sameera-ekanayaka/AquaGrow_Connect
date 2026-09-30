import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import 'auth_providers.dart';
import 'profile_screen.dart';
import 'register_screen.dart';

/// Biophilic aesthetic login screen featuring glassmorphic styling,
/// rigorous input validation, and single-tap viva demo credentials.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'grower@aquagrow.io');
  final _passwordController = TextEditingController(text: 'Password123');
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _fillDemoCredentials(String email, String password) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = password;
    });
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(authControllerProvider.notifier);
    final success = await controller.signIn(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
    }
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(text: _emailController.text);
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppColors.darkSurface,
          title: const Text(
            'Reset Password',
            style: TextStyle(color: AppColors.textDarkPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your registered email address to receive password recovery instructions.',
                style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: resetEmailController,
                style: const TextStyle(color: AppColors.textDarkPrimary),
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined, color: AppColors.mintAccent),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textDarkSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = resetEmailController.text.trim();
                if (email.isNotEmpty) {
                  await ref.read(authRepositoryProvider).resetPassword(email: email);
                  if (mounted) {
                    Navigator.of(dialogCtx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Recovery instructions dispatched to $email'),
                        backgroundColor: AppColors.primarySage,
                      ),
                    );
                  }
                }
              },
              child: const Text('Send Reset Link'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Botanical Header Branding
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primarySage.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.mintAccent, width: 2),
                      ),
                      child: const Icon(
                        Icons.eco_rounded,
                        color: AppColors.mintAccent,
                        size: 38,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'AquaGrow Connect',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displayMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Living Decor Hydroponic Management System',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),

                  // Glassmorphic Authentication Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.darkBorder,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Sign In',
                            style: theme.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Access your hydroponic command center',
                            style: TextStyle(
                              color: AppColors.textDarkSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Error Banner
                          if (authState.errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: AppColors.statusCritical.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.statusCritical.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: AppColors.statusCritical,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      authState.errorMessage!,
                                      style: const TextStyle(
                                        color: AppColors.statusCritical,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 16),
                                    color: AppColors.statusCritical,
                                    onPressed: () {
                                      ref.read(authControllerProvider.notifier).clearError();
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Email Input
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: AppColors.textDarkPrimary),
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: Icon(
                                Icons.alternate_email,
                                color: AppColors.mintAccent,
                                size: 20,
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter your email.';
                              }
                              if (!val.contains('@') || !val.contains('.')) {
                                return 'Please enter a valid email address.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password Input
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: AppColors.textDarkPrimary),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: AppColors.mintAccent,
                                size: 20,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.textDarkSecondary,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Please enter your password.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),

                          // Forgot Password Action
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _showForgotPasswordDialog,
                              child: const Text(
                                'Forgot password?',
                                style: TextStyle(
                                  color: AppColors.mintAccent,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Primary Sign In Button
                          ElevatedButton(
                            onPressed: authState.isLoading ? null : _handleLogin,
                            child: authState.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.darkBackground,
                                      ),
                                    ),
                                  )
                                : const Text('Sign In to AquaGrow'),
                          ),
                          const SizedBox(height: 20),

                          // Navigation to Register Screen
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'New to AquaGrow?',
                                style: TextStyle(
                                  color: AppColors.textDarkSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const RegisterScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Create an Account',
                                  style: TextStyle(
                                    color: AppColors.mintAccent,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Single-Tap Viva Demonstration Credentials Bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurfaceElevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.darkBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Demo Credentials (Viva & Examiner Evaluation):',
                          style: TextStyle(
                            color: AppColors.textDarkSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ActionChip(
                              backgroundColor: AppColors.darkSurface,
                              side: const BorderSide(color: AppColors.primarySage),
                              avatar: const Icon(
                                Icons.admin_panel_settings_outlined,
                                color: AppColors.mintAccent,
                                size: 16,
                              ),
                              label: const Text(
                                'Owner Demo',
                                style: TextStyle(color: AppColors.textDarkPrimary, fontSize: 12),
                              ),
                              onPressed: () => _fillDemoCredentials(
                                'grower@aquagrow.io',
                                'Password123',
                              ),
                            ),
                            ActionChip(
                              backgroundColor: AppColors.darkSurface,
                              side: const BorderSide(color: AppColors.darkBorder),
                              avatar: const Icon(
                                Icons.remove_red_eye_outlined,
                                color: AppColors.textDarkSecondary,
                                size: 16,
                              ),
                              label: const Text(
                                'Viewer Demo',
                                style: TextStyle(color: AppColors.textDarkPrimary, fontSize: 12),
                              ),
                              onPressed: () => _fillDemoCredentials(
                                'viewer@aquagrow.io',
                                'Password123',
                              ),
                            ),
                            ActionChip(
                              backgroundColor: AppColors.darkSurface,
                              side: const BorderSide(color: AppColors.darkBorder),
                              avatar: const Icon(
                                Icons.business_center_outlined,
                                color: AppColors.mintAccent,
                                size: 16,
                              ),
                              label: const Text(
                                'Commercial Demo',
                                style: TextStyle(color: AppColors.textDarkPrimary, fontSize: 12),
                              ),
                              onPressed: () => _fillDemoCredentials(
                                'commercial@aquagrow.io',
                                'Password123',
                              ),
                            ),
                          ],
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
    );
  }
}
