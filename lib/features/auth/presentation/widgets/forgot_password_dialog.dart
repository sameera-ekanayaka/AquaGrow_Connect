import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/core/utils/validators.dart';
import 'package:aquagrow_mobile/features/auth/presentation/auth_providers.dart';
import 'package:aquagrow_mobile/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the forgot password dialog, starting with [email] typed in.
///
/// When the reset email is sent the dialog closes and a SnackBar confirms
/// where it went. Errors stay inside the dialog so the user can retry.
Future<void> showForgotPasswordDialog(BuildContext context, {String? email}) {
  return showDialog<void>(
    context: context,
    builder: (_) => ForgotPasswordDialog(initialEmail: email ?? ''),
  );
}

/// Asks for an email address and sends a password reset link to it.
class ForgotPasswordDialog extends ConsumerStatefulWidget {
  /// Creates the dialog with [initialEmail] already typed in.
  const ForgotPasswordDialog({this.initialEmail = '', super.key});

  /// Email copied from the sign-in form, so the user rarely retypes it.
  final String initialEmail;

  @override
  ConsumerState<ForgotPasswordDialog> createState() =>
      _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends ConsumerState<ForgotPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail.trim());
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _sending = true;
      _error = null;
    });

    final email = _email.text.trim();
    final error =
        await ref.read(authControllerProvider.notifier).resetPassword(email);
    if (!mounted) return;

    if (error != null) {
      setState(() {
        _sending = false;
        _error = error;
      });
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Reset link sent to $email. Check your inbox and spam folder.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final error = _error;

    return AlertDialog(
      title: const Text('Reset your password'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter your account email and we will send you a link to choose '
              'a new password.',
              style: text.bodyMedium?.copyWith(color: context.ag.textSecondary),
            ),
            const SizedBox(height: AgSpace.s16),
            TextFormField(
              key: const Key('reset-email'),
              controller: _email,
              enabled: !_sending,
              autofocus: widget.initialEmail.isEmpty,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.send,
              onFieldSubmitted: (_) => _send(),
              validator: Validators.email,
              decoration: const InputDecoration(
                hintText: 'you@example.com',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: AgSpace.s12),
              AuthErrorBanner(error),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _sending ? null : _send,
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, kMinTouchTarget),
          ),
          child: _sending ? const ButtonSpinner() : const Text('Send link'),
        ),
      ],
    );
  }
}
