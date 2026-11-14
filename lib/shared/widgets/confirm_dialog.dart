import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// Asks the user to confirm a risky action and returns `true` only if they
/// tapped the confirm button.
///
/// RULE (lecture 5): logout, pump on/off, pH dosing, delete and harvest must
/// all go through this dialog. Never trigger them from a single tap.
///
/// ```dart
/// final ok = await showConfirmDialog(
///   context,
///   title: 'Turn the pump off?',
///   message: 'Plants in Pod Alpha will not get water until you turn it back on.',
///   confirmLabel: 'Turn off',
///   destructive: true,
/// );
/// if (ok) { ... }
/// ```
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final c = dialogContext.ag;
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: c.critical,
                    foregroundColor: c.onDark,
                    minimumSize: const Size(kMinTouchTarget * 2, kMinTouchTarget),
                  )
                : FilledButton.styleFrom(
                    minimumSize: const Size(kMinTouchTarget * 2, kMinTouchTarget),
                  ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
