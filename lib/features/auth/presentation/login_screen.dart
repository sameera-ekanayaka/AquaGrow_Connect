import 'dart:async';

import 'package:aquagrow_mobile/app/router/app_routes.dart';
import 'package:aquagrow_mobile/core/constants/app_constants.dart';
import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/core/utils/validators.dart';
import 'package:aquagrow_mobile/features/auth/presentation/auth_providers.dart';
import 'package:aquagrow_mobile/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:aquagrow_mobile/features/auth/presentation/widgets/forgot_password_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Password of the demo account. Only used by "Use demo account"; in
/// simulation mode any valid email and password signs in.
const kDemoPassword = 'Password123';

/// "Auth · Sign in" from Figma: email, password, forgot password, sign in,
/// and a one-tap demo account for the viva.
///
/// After a successful sign-in the router moves to Home by itself (see
/// `AuthSession`), so this screen never navigates on success.
class LoginScreen extends ConsumerStatefulWidget {
  /// Creates the sign-in screen.
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hidePassword = true;

  @override
  void initState() {
    super.initState();
    // Do not carry an error over from the register screen.
    Future.microtask(
      () => ref.read(authControllerProvider.notifier).clearError(),
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    TextInput.finishAutofillContext();
    await ref
        .read(authControllerProvider.notifier)
        .signIn(_email.text.trim(), _password.text);
  }

  Future<void> _useDemoAccount() async {
    _email.text = AppConstants.mockOwnerEmail;
    _password.text = kDemoPassword;
    await _signIn();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final error = state.errorMessage;
    final busy = state.isLoading;

    return AuthPage(
      children: [
        const AuthLogo(),
        const SizedBox(height: AgSpace.s24),
        const AuthHeader(
          title: 'Welcome back',
          subtitle: 'Sign in to check on your pods.',
        ),
        const SizedBox(height: AgSpace.s32),
        Form(
          key: _formKey,
          // Each field checks itself as soon as the user types in it.
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const FieldLabel('Email'),
                TextFormField(
                  key: const Key('login-email'),
                  controller: _email,
                  enabled: !busy,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                  decoration: const InputDecoration(
                    hintText: 'you@example.com',
                    prefixIcon: Icon(Icons.mail_outline_rounded),
                  ),
                ),
                const SizedBox(height: AgSpace.s16),
                const FieldLabel('Password'),
                TextFormField(
                  key: const Key('login-password'),
                  controller: _password,
                  enabled: !busy,
                  obscureText: _hidePassword,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _signIn(),
                  validator: Validators.password,
                  decoration: InputDecoration(
                    hintText: 'Your password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      tooltip:
                          _hidePassword ? 'Show password' : 'Hide password',
                      onPressed: () =>
                          setState(() => _hidePassword = !_hidePassword),
                      icon: Icon(
                        _hidePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: busy
                ? null
                : () => showForgotPasswordDialog(context, email: _email.text),
            child: const Text('Forgot password?'),
          ),
        ),
        if (error != null) ...[
          AuthErrorBanner(error),
          const SizedBox(height: AgSpace.s16),
        ] else
          const SizedBox(height: AgSpace.s8),
        FilledButton(
          key: const Key('login-submit'),
          onPressed: busy ? null : _signIn,
          child: busy ? const ButtonSpinner() : const Text('Sign in'),
        ),
        const SizedBox(height: AgSpace.s12),
        OutlinedButton(
          key: const Key('login-demo'),
          onPressed: busy ? null : () => unawaited(_useDemoAccount()),
          child: const Text('Use demo account'),
        ),
        const SizedBox(height: AgSpace.s24),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'New here?',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: context.ag.textSecondary),
            ),
            TextButton(
              onPressed: busy ? null : () => context.push(AppRoutes.register),
              child: const Text('Create an account'),
            ),
          ],
        ),
      ],
    );
  }
}
