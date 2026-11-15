import 'package:aquagrow_mobile/core/constants/app_colors.dart';
import 'package:aquagrow_mobile/core/models/hydro_supplier.dart';
import 'package:aquagrow_mobile/core/services/geo_service.dart';
import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/features/location/presentation/location_providers.dart';
import 'package:aquagrow_mobile/features/location/widgets/supplier_pin_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Interactive Hydro-Hub supply directory screen with GPS distance computation,
/// category filtering, product search, and verified supplier details.
class HydroMapScreen extends ConsumerWidget {
  /// Creates the [HydroMapScreen].
  const HydroMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppliers = ref.watch(sortedSuppliersProvider);
    final selectedCategory = ref.watch(selectedSupplierCategoryProvider);
    final positionAsync = ref.watch(currentPositionProvider);
    final colors = context.ag;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryTextColor = isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary;
    final secondaryTextColor = isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary;
    final userPos = positionAsync.value;

    final categories = [
      'All',
      'Nutrients & Buffers',
      'Rockwool & Growing Media',
      'LED Lights & Aeration Pumps',
      'Seeds & Genetics',
      'Full Systems & Sensors',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hydro-Hub Supply Network'),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh GPS & Suppliers',
            icon: const Icon(Icons.my_location),
            onPressed: () {
              ref.invalidate(currentPositionProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // GPS Location Status Bar
          _GpsStatusBar(userPos: userPos),

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AgSpace.screen,
              AgSpace.s12,
              AgSpace.screen,
              AgSpace.s8,
            ),
            child: TextField(
              onChanged: (val) =>
                  ref.read(supplierSearchQueryProvider.notifier).state = val,
              decoration: InputDecoration(
                hintText: 'Search nutrient buffers, rockwool, seeds...',
                hintStyle: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: colors.textSecondary),
                prefixIcon: Icon(Icons.search, size: 20, color: colors.brand),
                suffixIcon: ref.watch(supplierSearchQueryProvider).isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () =>
                            ref
                                .read(supplierSearchQueryProvider.notifier)
                                .state = '',
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: AgSpace.s16,
                ),
                filled: true,
                fillColor: colors.surface,
                border: OutlineInputBorder(
                  borderRadius: AgRadius.all(AgRadius.r16),
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AgRadius.all(AgRadius.r16),
                  borderSide: BorderSide(color: colors.border),
                ),
              ),
            ),
          ),

          // Horizontal Category Filter Chips
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AgSpace.screen,
                vertical: AgSpace.s8,
              ),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: AgSpace.s8),
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category == selectedCategory;

                return FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  selectedColor: colors.brandSurface,
                  backgroundColor: colors.surface,
                  labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? colors.brand : colors.textSecondary,
                      ),
                  side: BorderSide(
                    color: isSelected ? colors.brand : colors.border,
                  ),
                  onSelected: (_) {
                    ref
                        .read(selectedSupplierCategoryProvider.notifier)
                        .state = category;
                  },
                );
              },
            ),
          ),

          const SizedBox(height: AgSpace.s8),

          // Suppliers List or Empty State
          Expanded(
            child: suppliers.isEmpty
                ? _EmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: suppliers.length,
                    itemBuilder: (context, index) {
                      final supplier = suppliers[index];
                      return _buildSupplierCard(context, supplier, userPos, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierCard(
    BuildContext context,
    HydroSupplier supplier,
    GeoPosition? userPos,
    bool isDark,
  ) {
    final primaryTextColor = isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary;
    final secondaryTextColor = isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary;

    final double? distanceKm = userPos != null
        ? supplier.distanceInKmFrom(userPos.latitude, userPos.longitude)
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          SupplierPinModal.show(
            context,
            supplier: supplier,
            userLatitude: userPos?.latitude,
            userLongitude: userPos?.longitude,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title & Distance
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            supplier.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: primaryTextColor,
                            ),
                          ),
                        ),
                        if (supplier.isVerified) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified, color: AppColors.mintAccent, size: 16),
                        ],
                      ],
                    ),
                  ),
                  if (distanceKm != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primarySage.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${distanceKm.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.mintAccent,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 4),

              Text(
                '${supplier.category} • ${supplier.city}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.mintAccent,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                supplier.address,
                style: TextStyle(fontSize: 12, color: secondaryTextColor),
              ),

              const SizedBox(height: 10),

              // Product Tags Preview
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: supplier.featuredProducts.take(3).map((prod) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      prod,
                      style: TextStyle(fontSize: 10, color: secondaryTextColor),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Color(0xFFF4A261)),
                      const SizedBox(width: 4),
                      Text(
                        '${supplier.rating}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryTextColor),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.schedule, size: 14, color: AppColors.mintAccent),
                      const SizedBox(width: 4),
                      Text(
                        supplier.openHours,
                        style: TextStyle(fontSize: 11, color: secondaryTextColor),
                      ),
                    ],
                  ),
                  const Row(
                    children: [
                      Text(
                        'Details',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.mintAccent),
                      ),
                      Icon(Icons.chevron_right, size: 16, color: AppColors.mintAccent),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty state shown when the filtered supplier list has no results.
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.ag;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.store_mall_directory_outlined,
            size: 48,
            color: colors.textSecondary,
          ),
          const SizedBox(height: AgSpace.s12),
          Text(
            'No hydroponic suppliers found',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.text,
                ),
          ),
          const SizedBox(height: AgSpace.s4),
          Text(
            'Try clearing search filters or changing category',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
  /// Creates a [_GpsStatusBar] with the given [userPos].
  const _GpsStatusBar({required this.userPos});

  /// Current GPS position, or `null` while acquiring.
  final GeoPosition? userPos;

  @override
  Widget build(BuildContext context) {
    final colors = context.ag;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AgSpace.screen,
        vertical: AgSpace.s8,
      ),
      color: colors.subtle,
      child: Row(
        children: [
          Icon(Icons.satellite_alt_outlined, size: 18, color: colors.brand),
          const SizedBox(width: AgSpace.s8),
          Expanded(
            child: Text(
              userPos != null
                  ? '${userPos!.locationSource}: '
                      '${userPos!.latitude.toStringAsFixed(4)}°, '
                      '${userPos!.longitude.toStringAsFixed(4)}°'
                  : 'Acquiring GPS Fix...',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: colors.textSecondary),
            ),
          ),
          if (userPos != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AgSpace.s8,
                vertical: AgSpace.s4,
              ),
              decoration: BoxDecoration(
                color: colors.brandSurface,
                borderRadius: AgRadius.all(AgRadius.r16),
              ),
              child: Text(
                '±${userPos!.accuracyMeters.toStringAsFixed(0)}m',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.brand,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}
