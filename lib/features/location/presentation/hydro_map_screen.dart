import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/hydro_supplier.dart';
import '../widgets/supplier_pin_modal.dart';
import 'location_providers.dart';

/// Interactive Hydro-Hub supply directory screen with GPS distance computation,
/// category filtering, product search, and verified supplier details.
class HydroMapScreen extends ConsumerWidget {
  const HydroMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppliers = ref.watch(sortedSuppliersProvider);
    final selectedCategory = ref.watch(selectedSupplierCategoryProvider);
    final positionAsync = ref.watch(currentPositionProvider);
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
          // GPS Location Status Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
            child: Row(
              children: [
                const Icon(Icons.satellite_alt_outlined, size: 18, color: AppColors.mintAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    userPos != null
                        ? '${userPos.locationSource}: ${userPos.latitude.toStringAsFixed(4)}°, ${userPos.longitude.toStringAsFixed(4)}°'
                        : 'Acquiring GPS Fix...',
                    style: TextStyle(fontSize: 12, color: secondaryTextColor),
                  ),
                ),
                if (userPos != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.mintAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '±${userPos.accuracyMeters.toStringAsFixed(0)}m',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.mintAccent),
                    ),
                  ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: TextField(
              onChanged: (val) => ref.read(supplierSearchQueryProvider.notifier).state = val,
              decoration: InputDecoration(
                hintText: 'Search nutrient buffers, rockwool, seeds...',
                hintStyle: TextStyle(fontSize: 13, color: secondaryTextColor),
                prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.mintAccent),
                suffixIcon: ref.watch(supplierSearchQueryProvider).isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => ref.read(supplierSearchQueryProvider.notifier).state = '',
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
              ),
            ),
          ),

          // Horizontal Category Filter Pills
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category == selectedCategory;

                return FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  selectedColor: AppColors.primarySage,
                  backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : secondaryTextColor,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppColors.mintAccent : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  onSelected: (_) {
                    ref.read(selectedSupplierCategoryProvider.notifier).state = category;
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 6),

          // Suppliers List
          Expanded(
            child: suppliers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.store_mall_directory_outlined, size: 48, color: AppColors.textDarkSecondary),
                        const SizedBox(height: 12),
                        Text(
                          'No hydroponic suppliers found',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primaryTextColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Try clearing search filters or changing category',
                          style: TextStyle(fontSize: 12, color: secondaryTextColor),
                        ),
                      ],
                    ),
                  )
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
    dynamic userPos,
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
