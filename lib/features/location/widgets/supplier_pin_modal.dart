import 'package:aquagrow_mobile/core/constants/app_colors.dart';
import 'package:aquagrow_mobile/core/models/hydro_supplier.dart';
import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// Modal bottom sheet displaying verified hydroponic retailer profile,
/// inventory highlights, GPS coordinates, and direct contact options.
class SupplierPinModal extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final colors = context.ag;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary;
    final secondaryTextColor = isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary;

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

            // Header Title & Verification Badge
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
                              color: colors.brand,
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
                            color: colors.brand,
                          ),
                    ),
                  ),
              ],
            ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Rating, Open Hours & Address
          Row(
            children: [
              const Icon(Icons.star, color: Color(0xFFF4A261), size: 18),
              const SizedBox(width: 6),
              Text(
                '${supplier.rating} / 5.0',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryTextColor),
              ),
              const SizedBox(width: 20),
              const Icon(Icons.schedule, color: AppColors.mintAccent, size: 18),
              const SizedBox(width: 6),
              Text(
                supplier.openHours,
                style: TextStyle(fontSize: 12, color: secondaryTextColor),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.pin_drop_outlined, color: AppColors.mintAccent, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  supplier.address,
                  style: TextStyle(fontSize: 13, color: primaryTextColor),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Stocked Supplies Badges
          Text(
            'Verified In-Stock Hydroponic Inventory',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: secondaryTextColor,
            ),
          ),
          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: supplier.featuredProducts.map((product) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 14, color: AppColors.mintAccent),
                    const SizedBox(width: 6),
                    Text(
                      product,
                      style: TextStyle(
                        fontSize: 12,
                        color: primaryTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Action Buttons: Call & Navigate
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Dialing ${supplier.phone}...')),
                    );
                  },
                  icon: const Icon(Icons.phone, size: 18),
                  label: Text(supplier.phone),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Navigating to ${supplier.name}...')),
                    );
                  },
                  icon: const Icon(Icons.directions, size: 18),
                  label: const Text('Directions'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

