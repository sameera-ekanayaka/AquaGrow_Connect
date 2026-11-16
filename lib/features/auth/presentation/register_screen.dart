import 'package:aquagrow_mobile/app/router/app_routes.dart';
import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/core/utils/validators.dart';
import 'package:aquagrow_mobile/features/auth/presentation/auth_providers.dart';
import 'package:aquagrow_mobile/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// "Auth · Create account" from Figma: name, email, password and a
/// confirmation, then one Create account button.
///
/// New accounts are pod owners. After sign-up the router moves to Home by
/// itself (see `AuthSession`).
class RegisterScreen extends ConsumerStatefulWidget {
  /// Creates the register screen.
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _hidePassword = true;

  @override
  void initState() {
    super.initState();
    // Do not carry an error over from the sign-in screen.
    Future.microtask(
      () => ref.read(authControllerProvider.notifier).clearError(),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _confirmValidator(String? value) {
    if ((value ?? '').isEmpty) return 'Repeat your password';
    if (value != _password.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    TextInput.finishAutofillContext();
    await ref.read(authControllerProvider.notifier).signUp(
          email: _email.text.trim(),
          password: _password.text,
          fullName: _name.text.trim(),
        );
  }

  void _backToSignIn() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final error = state.errorMessage;
    final busy = state.isLoading;

    return AuthPage(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to sign in',
          onPressed: busy ? null : _backToSignIn,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      children: [
        const AuthHeader(
          title: 'Create your account',
          subtitle: 'Your pods and readings stay private to you.',
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
                const FieldLabel('Full name'),
                TextFormField(
                  key: const Key('register-name'),
                  controller: _name,
                  enabled: !busy,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  textInputAction: TextInputAction.next,
                  validator: (v) => Validators.required(v, field: 'Your name'),
                  decoration: const InputDecoration(
                    hintText: 'Your name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: AgSpace.s16),
                const FieldLabel('Email'),
                TextFormField(
                  key: const Key('register-email'),
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
                  key: const Key('register-password'),
                  controller: _password,
                  enabled: !busy,
                  obscureText: _hidePassword,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.next,
                  validator: Validators.password,
                  decoration: InputDecoration(
                    hintText: 'At least 8 characters',
                    helperText: 'Use letters and numbers.',
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
                const SizedBox(height: AgSpace.s16),
                const FieldLabel('Confirm password'),
                TextFormField(
                  key: const Key('register-confirm'),
                  controller: _confirm,
                  enabled: !busy,
                  obscureText: _hidePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _register(),
                  validator: _confirmValidator,
                  decoration: const InputDecoration(
                    hintText: 'Repeat your password',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AgSpace.s24),
        if (error != null) ...[
          AuthErrorBanner(error),
          const SizedBox(height: AgSpace.s16),
        ],
        FilledButton(
          key: const Key('register-submit'),
          onPressed: busy ? null : _register,
          child: busy ? const ButtonSpinner() : const Text('Create account'),
        ),
        const SizedBox(height: AgSpace.s24),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Already have an account?',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: context.ag.textSecondary),
            ),
            TextButton(
              onPressed: busy ? null : _backToSignIn,
              child: const Text('Sign in'),
            ),
          ],
        ),
      ],
    );
  }
}
