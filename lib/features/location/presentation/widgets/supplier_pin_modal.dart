import 'package:aquagrow_mobile/core/models/hydro_supplier.dart';
import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/features/location/application/location_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Modal bottom sheet displaying verified hydroponic retailer profile,
/// inventory highlights, GPS coordinates, and direct contact options.
class SupplierPinModal extends ConsumerWidget {
  /// Creates a [SupplierPinModal] for the given [supplier].
  const SupplierPinModal({
    super.key,
    required this.supplier,
    this.userLatitude,
    this.userLongitude,
  });

  /// The hydroponic supplier to display.
  final HydroSupplier supplier;

  /// User's latitude for distance calculation, or `null` if unavailable.
  final double? userLatitude;

  /// User's longitude for distance calculation, or `null` if unavailable.
  final double? userLongitude;

  /// Shows this modal as a bottom sheet over [context].
  static void show(
    BuildContext context, {
    required HydroSupplier supplier,
    double? userLatitude,
    double? userLongitude,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SupplierPinModal(
        supplier: supplier,
        userLatitude: userLatitude,
        userLongitude: userLongitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.ag;

    final double? distanceKm = (userLatitude != null && userLongitude != null)
        ? supplier.distanceInKmFrom(userLatitude!, userLongitude!)
        : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AgSpace.s24,
        AgSpace.s12,
        AgSpace.s24,
        AgSpace.s32,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AgRadius.r24)),
        border: Border.all(color: colors.border),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AgSpace.s20),
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: AgRadius.all(AgRadius.r16),
                ),
              ),
            ),

            // Header: Name, Verified Badge, Distance Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              supplier.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colors.text,
                                  ),
                            ),
                          ),
                          if (supplier.isVerified) ...[
                            const SizedBox(width: AgSpace.s8),
                            Icon(
                              Icons.verified,
                              color: colors.brand,
                              size: 20,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AgSpace.s4),
                      Text(
                        '${supplier.category} • ${supplier.city}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: colors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                if (distanceKm != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AgSpace.s12,
                      vertical: AgSpace.s8,
                    ),
                    decoration: BoxDecoration(
                      color: colors.brandSurface,
                      borderRadius: AgRadius.all(AgRadius.r16),
                    ),
                    child: Text(
                      '${distanceKm.toStringAsFixed(1)} km',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.text,
                          ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: AgSpace.s16),
            const Divider(height: 1),
            const SizedBox(height: AgSpace.s16),

            // Rating, Open Hours & Address
            Row(
              children: [
                // Star colour is amber/orange — no exact design token;
                // colors.warning is the closest warm accent in the token set.
                Icon(Icons.star, color: colors.warning, size: 18),
                const SizedBox(width: AgSpace.s8),
                Text(
                  '${supplier.rating} / 5.0',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.text,
                      ),
                ),
                const SizedBox(width: AgSpace.s20),
                Icon(Icons.schedule, color: colors.brand, size: 18),
                const SizedBox(width: AgSpace.s8),
                Text(
                  supplier.openHours,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: colors.textSecondary),
                ),
              ],
            ),

            const SizedBox(height: AgSpace.s12),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.pin_drop_outlined, color: colors.brand, size: 18),
                const SizedBox(width: AgSpace.s8),
                Expanded(
                  child: Text(
                    supplier.address,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: colors.text),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AgSpace.s20),

            // Stocked Supplies Badges
            Text(
              'Verified In-Stock Hydroponic Inventory',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: colors.textSecondary,
                  ),
            ),
            const SizedBox(height: AgSpace.s12),

            Wrap(
              spacing: AgSpace.s8,
              runSpacing: AgSpace.s8,
              children: supplier.featuredProducts.map((product) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AgSpace.s12,
                    vertical: AgSpace.s8,
                  ),
                  decoration: BoxDecoration(
                    color: colors.subtle,
                    borderRadius: AgRadius.all(AgRadius.r16),
                    border: Border.all(color: colors.border, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 14,
                        color: colors.brand,
                      ),
                      const SizedBox(width: AgSpace.s8),
                      Text(
                        product,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.text,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: AgSpace.s24),

            // Action Buttons: Call & Navigate
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final launcher = ref.read(launcherServiceProvider);
                      final success = await launcher.dial(supplier.phone);
                      if (!success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Could not open the phone app'),
                            action: SnackBarAction(
                              label: 'Copy',
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: supplier.phone),
                                );
                              },
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.phone, size: 18),
                    label: Text(supplier.phone),
                    style: OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: AgSpace.s12),
                      shape: RoundedRectangleBorder(
                        borderRadius: AgRadius.all(AgRadius.r16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AgSpace.s12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final launcher = ref.read(launcherServiceProvider);
                      final success = await launcher.openDirections(
                        latitude: supplier.latitude,
                        longitude: supplier.longitude,
                        label: supplier.name,
                      );
                      if (!success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Could not open maps'),
                            action: SnackBarAction(
                              label: 'Copy',
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: supplier.address),
                                );
                              },
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.directions, size: 18),
                    label: const Text('Directions'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
