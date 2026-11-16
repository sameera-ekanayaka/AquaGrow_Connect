import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/features/auth/presentation/auth_providers.dart';
import 'package:aquagrow_mobile/shared/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Triggers the defensive two-step account deletion flow.
Future<void> showDeleteAccountFlow(BuildContext context, WidgetRef ref) async {
  final firstConfirm = await showConfirmDialog(
    context,
    title: 'Delete account?',
    message: 'Delete your account and all pod history? This cannot be undone.',
    confirmLabel: 'Delete account',
    destructive: true,
  );
  if (!firstConfirm || !context.mounted) return;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const _DeleteConfirmationDialog(),
  );
}

class _DeleteConfirmationDialog extends ConsumerStatefulWidget {
  const _DeleteConfirmationDialog();

  @override
  ConsumerState<_DeleteConfirmationDialog> createState() =>
      _DeleteConfirmationDialogState();
}

class _DeleteConfirmationDialogState
    extends ConsumerState<_DeleteConfirmationDialog> {
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _confirmationController.text.trim() == 'DELETE' &&
      _passwordController.text.isNotEmpty &&
      !_isLoading;

  Future<void> _handleDelete() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final success = await ref
        .read(authControllerProvider.notifier)
        .deleteAccount(password: _passwordController.text);

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _isLoading = false;
        _error = ref.read(authControllerProvider).errorMessage ??
            'Could not delete account. Check your password.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ag;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AgRadius.all(AgRadius.r20),
        side: BorderSide(color: colors.border),
      ),
      title: Text('Final confirmation', style: textTheme.titleLarge),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To confirm deletion, enter your password and type DELETE below.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: AgSpace.s16),
            TextField(
              key: const Key('delete-password-input'),
              controller: _passwordController,
              obscureText: true,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Account password',
              ),
            ),
            const SizedBox(height: AgSpace.s12),
            TextField(
              key: const Key('delete-confirm-input'),
              controller: _confirmationController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Type DELETE',
                hintText: 'DELETE',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AgSpace.s12),
              Text(
                _error!,
                style: textTheme.bodySmall?.copyWith(color: colors.critical),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('delete-confirm-btn'),
          onPressed: _canSubmit ? _handleDelete : null,
          style: FilledButton.styleFrom(
            backgroundColor: colors.critical,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Delete permanently'),
        ),
      ],
    );
  }
}
