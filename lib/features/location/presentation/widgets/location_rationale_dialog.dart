import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// Dialog that explains why AquaGrow Connect needs location access before the
/// OS permission prompt is shown to the user.
///
/// Returns `true` via [Navigator.pop] when the user taps **Allow**,
/// and `false` when they tap **Not now**.
class LocationRationaleDialog extends StatelessWidget {
  /// Creates a [LocationRationaleDialog].
  const LocationRationaleDialog({super.key});

  /// Displays the dialog and returns the user's decision.
  ///
  /// Call this before triggering the OS location permission request.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const LocationRationaleDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ag;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AgRadius.all(AgRadius.r20),
      ),
      icon: Icon(
        Icons.location_on_outlined,
        color: colors.brand,
        size: 36,
      ),
      title: Text(
        'Use your location?',
        style: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: colors.text,
        ),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'AquaGrow Connect uses your location to:',
            style: textTheme.bodyMedium?.copyWith(
              color: colors.text,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AgSpace.s12),
          _buildBullet(
            context,
            icon: Icons.wb_sunny_outlined,
            text: 'Show real-time local weather for accurate VPD calculations.',
          ),
          const SizedBox(height: AgSpace.s8),
          _buildBullet(
            context,
            icon: Icons.store_mall_directory_outlined,
            text: 'Find nearby hydroponic suppliers sorted by distance.',
          ),
          const SizedBox(height: AgSpace.s12),
          Text(
            'Location is only read while you use the app and is never stored on our servers.',
            style: textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.end,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Not now',
            style: textTheme.labelLarge?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Allow'),
        ),
      ],
    );
  }

  Widget _buildBullet(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    final colors = context.ag;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: colors.brand),
        const SizedBox(width: AgSpace.s8),
        Expanded(
          child: Text(
            text,
            style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
        ),
      ],
    );
  }
}
