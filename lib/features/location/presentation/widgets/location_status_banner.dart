import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/features/location/domain/location_access_status.dart';
import 'package:aquagrow_mobile/features/location/presentation/location_providers.dart';
import 'package:aquagrow_mobile/features/location/presentation/widgets/location_rationale_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Contextual banner shown beneath the weather card when location access
/// is degraded (denied, permanently denied, or GPS is off).
///
/// When [result.isFallback] is false the widget returns [SizedBox.shrink].
/// Each degraded state offers an action button that attempts recovery:
///
/// - **denied** → "Try again" presents [LocationRationaleDialog], then refreshes [locationResultProvider].
/// - **permanentlyDenied** → "Open settings" opens OS app-settings.
/// - **serviceDisabled** → "Enable GPS" opens OS location settings.
class LocationStatusBanner extends ConsumerWidget {
  /// Creates a [LocationStatusBanner] for the given [result].
  const LocationStatusBanner({super.key, required this.result});

  /// The current location acquisition result to display status for.
  final LocationResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!result.isFallback) return const SizedBox.shrink();

    final colors = context.ag;
    final textTheme = Theme.of(context).textTheme;

    final (
      IconData icon,
      String label,
      String actionLabel,
      VoidCallback action
    ) = switch (result.status) {
      LocationAccessStatus.denied => (
          Icons.location_off_outlined,
          result.fallbackReason ?? 'GPS unavailable, showing Colombo',
          'Use my location',
          () async {
            final allow = await LocationRationaleDialog.show(context);
            if (allow) {
              ref.read(locationConsentProvider.notifier).state = true;
              await ref.read(preferencesStoreProvider).setBool(
                    kLocationConsentPrefKey,
                    value: true,
                  );
              ref.invalidate(locationResultProvider);
            }
          },
        ),
      LocationAccessStatus.permanentlyDenied => (
          Icons.lock_outline,
          result.fallbackReason ??
              'Location permanently denied. Enable it in app settings.',
          'Open settings',
          () async => Geolocator.openAppSettings(),
        ),
      LocationAccessStatus.serviceDisabled => (
          Icons.gps_off,
          result.fallbackReason ??
              'Device GPS is off. Showing Colombo weather.',
          'Enable GPS',
          () async => Geolocator.openLocationSettings(),
        ),
      LocationAccessStatus.granted => (
          Icons.check_circle_outline,
          '',
          '',
          () {},
        ),
    };

    if (result.status == LocationAccessStatus.granted) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AgSpace.s12),
      padding: const EdgeInsets.symmetric(
        horizontal: AgSpace.s12,
        vertical: AgSpace.s8,
      ),
      decoration: BoxDecoration(
        color: colors.warningSurface,
        borderRadius: AgRadius.all(AgRadius.r16),
        border: Border.all(color: colors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.warning),
          const SizedBox(width: AgSpace.s8),
          Expanded(
            child: Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: colors.warning,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: AgSpace.s4),
          TextButton(
            onPressed: action,
            style: TextButton.styleFrom(
              foregroundColor: colors.warning,
              padding: const EdgeInsets.symmetric(
                horizontal: AgSpace.s8,
                vertical: AgSpace.s4,
              ),
              minimumSize: const Size(0, kMinTouchTarget),
            ),
            child: Text(
              actionLabel,
              style: textTheme.labelSmall?.copyWith(
                color: colors.warning,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
