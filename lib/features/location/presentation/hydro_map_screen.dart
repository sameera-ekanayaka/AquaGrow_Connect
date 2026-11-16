import 'package:aquagrow_mobile/core/models/hydro_supplier.dart';
import 'package:aquagrow_mobile/core/services/geo_service.dart';
import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/features/location/application/location_providers.dart';
import 'package:aquagrow_mobile/features/location/presentation/widgets/supplier_map_view.dart';
import 'package:aquagrow_mobile/features/location/presentation/widgets/supplier_pin_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Interactive hydroponic supplier directory with GPS distance, category
/// filters, product search and verified supplier details.
class HydroMapScreen extends ConsumerStatefulWidget {
  /// Creates the [HydroMapScreen].
  const HydroMapScreen({super.key});

  @override
  ConsumerState<HydroMapScreen> createState() => _HydroMapScreenState();
}

class _HydroMapScreenState extends ConsumerState<HydroMapScreen> {
  static const _categories = [
    'All',
    'Nutrients & Buffers',
    'Rockwool & Growing Media',
    'LED Lights & Aeration Pumps',
    'Seeds & Genetics',
    'Full Systems & Sensors',
  ];

  /// Owns the search text so rotation keeps it and Clear can empty it.
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(supplierSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(supplierSearchQueryProvider.notifier).state = '';
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = ref.watch(sortedSuppliersProvider);
    final selectedCategory = ref.watch(selectedSupplierCategoryProvider);
    final positionAsync = ref.watch(currentPositionProvider);
    final hasQuery = ref.watch(supplierSearchQueryProvider).isNotEmpty;
    final viewMode = ref.watch(supplierViewModeProvider);
    final colors = context.ag;
    final userPos = positionAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hydroponic suppliers'),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh GPS and suppliers',
            icon: const Icon(Icons.my_location),
            onPressed: () => ref.invalidate(currentPositionProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          _GpsStatusBar(userPos: userPos),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AgSpace.screen,
              AgSpace.s12,
              AgSpace.screen,
              AgSpace.s8,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) =>
                  ref.read(supplierSearchQueryProvider.notifier).state = val,
              decoration: InputDecoration(
                hintText: 'Search nutrient buffers, rockwool, seeds...',
                hintStyle: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: colors.textSecondary),
                prefixIcon: Icon(Icons.search, size: 20, color: colors.brand),
                suffixIcon: hasQuery
                    ? IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: _clearSearch,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AgSpace.screen),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<SupplierViewMode>(
                segments: const [
                  ButtonSegment<SupplierViewMode>(
                    value: SupplierViewMode.list,
                    label: Text('List'),
                    icon: Icon(Icons.list, size: 18),
                  ),
                  ButtonSegment<SupplierViewMode>(
                    value: SupplierViewMode.map,
                    label: Text('Map'),
                    icon: Icon(Icons.map_outlined, size: 18),
                  ),
                ],
                selected: {viewMode},
                onSelectionChanged: (set) {
                  if (set.isNotEmpty) {
                    ref.read(supplierViewModeProvider.notifier).state =
                        set.first;
                  }
                },
                style: ButtonStyle(
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: AgRadius.all(AgRadius.r16),
                    ),
                  ),
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return colors.brandSurface;
                    }
                    return colors.surface;
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return colors.text;
                    }
                    return colors.textSecondary;
                  }),
                ),
              ),
            ),
          ),
          const SizedBox(height: AgSpace.s8),
          SizedBox(
            height: kMinTouchTarget,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AgSpace.screen,
                vertical: AgSpace.s8,
              ),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: AgSpace.s8),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == selectedCategory;

                return FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  selectedColor: colors.brandSurface,
                  backgroundColor: colors.surface,
                  labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? colors.text : colors.textSecondary,
                      ),
                  side: BorderSide(
                    color: isSelected ? colors.brand : colors.border,
                  ),
                  onSelected: (_) {
                    ref.read(selectedSupplierCategoryProvider.notifier).state =
                        category;
                  },
                );
              },
            ),
          ),
          const SizedBox(height: AgSpace.s8),
          Expanded(
            child: viewMode == SupplierViewMode.map
                ? const SupplierMapView()
                : (suppliers.isEmpty
                    ? _EmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AgSpace.screen,
                          vertical: AgSpace.s8,
                        ),
                        itemCount: suppliers.length,
                        itemBuilder: (context, index) {
                          return _SupplierCard(
                            supplier: suppliers[index],
                            userPos: userPos,
                          );
                        },
                      )),
          ),
        ],
      ),
    );
  }
}

/// GPS coordinates status bar shown at the top of [HydroMapScreen].
class _GpsStatusBar extends StatelessWidget {
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
              userPos == null ||
                      userPos!.isSimulated ||
                      userPos!.locationSource.contains('Fallback')
                  ? 'Showing suppliers near Colombo'
                  : 'GPS Active (${userPos!.latitude.toStringAsFixed(2)}°, ${userPos!.longitude.toStringAsFixed(2)}°)',
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
                      color: colors.text,
                    ),
              ),
            ),
        ],
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

/// A single supplier card in the [HydroMapScreen] list.
class _SupplierCard extends StatelessWidget {
  /// Creates a [_SupplierCard] for the given [supplier].
  const _SupplierCard({
    required this.supplier,
    required this.userPos,
  });

  /// The hydroponic supplier to display.
  final HydroSupplier supplier;

  /// Current user GPS position for distance calculation, or `null`.
  final GeoPosition? userPos;

  @override
  Widget build(BuildContext context) {
    final colors = context.ag;
    final double? distanceKm = userPos != null
        ? supplier.distanceInKmFrom(userPos!.latitude, userPos!.longitude)
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: AgSpace.s12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AgRadius.all(AgRadius.r16),
        border: Border.all(color: colors.border),
      ),
      child: InkWell(
        borderRadius: AgRadius.all(AgRadius.r16),
        onTap: () {
          SupplierPinModal.show(
            context,
            supplier: supplier,
            userLatitude: userPos?.latitude,
            userLongitude: userPos?.longitude,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(AgSpace.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name, Verified Badge & Distance
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            supplier.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colors.text,
                                ),
                          ),
                        ),
                        if (supplier.isVerified) ...[
                          const SizedBox(width: AgSpace.s8),
                          Icon(Icons.verified, color: colors.brand, size: 16),
                        ],
                      ],
                    ),
                  ),
                  if (distanceKm != null)
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
                        '${distanceKm.toStringAsFixed(1)} km',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.text,
                            ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: AgSpace.s4),

              Text(
                '${supplier.category} • ${supplier.city}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
                    ),
              ),

              const SizedBox(height: AgSpace.s8),

              Text(
                supplier.address,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: colors.textSecondary),
              ),

              const SizedBox(height: AgSpace.s12),

              // Product Tags Preview (up to 3)
              Wrap(
                spacing: AgSpace.s8,
                runSpacing: AgSpace.s4,
                children: supplier.featuredProducts.take(3).map((prod) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AgSpace.s8,
                      vertical: AgSpace.s4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.subtle,
                      borderRadius: AgRadius.all(AgRadius.r16),
                    ),
                    child: Text(
                      prod,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: colors.textSecondary),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: AgSpace.s12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Star colour is amber/orange — no exact design token;
                      // colors.warning is the closest warm accent in the token set.
                      Icon(Icons.star, size: 14, color: colors.warning),
                      const SizedBox(width: AgSpace.s4),
                      Text(
                        '${supplier.rating}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.text,
                            ),
                      ),
                      const SizedBox(width: AgSpace.s12),
                      Icon(Icons.schedule, size: 14, color: colors.brand),
                      const SizedBox(width: AgSpace.s4),
                      Text(
                        supplier.openHours,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: colors.textSecondary),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'Details',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.text,
                            ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: colors.textSecondary,
                      ),
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
