import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// Feedback notification displayed when the user shakes the device to refresh.
///
/// OWNER: Imasha (see docs/tasks/imasha.md).
abstract final class ShakeFeedback {
  /// Displays the "Refreshed" feedback snackbar using app design tokens.
  static void show(BuildContext context) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final colors = context.ag;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.refresh,
              size: 18,
              color: colors.brand,
            ),
            const SizedBox(width: AgSpace.s8),
            Text(
              'Refreshed',
              style: TextStyle(
                color: colors.text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: colors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AgRadius.all(AgRadius.r16),
          side: BorderSide(
            color: colors.border,
            width: 1,
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
