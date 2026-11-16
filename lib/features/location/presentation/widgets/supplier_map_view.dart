import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/features/location/application/location_providers.dart';
import 'package:aquagrow_mobile/features/location/presentation/widgets/supplier_pin_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

/// Interactive OpenStreetMap tile view displaying supplier locations and GPS position.
class SupplierMapView extends ConsumerStatefulWidget {
  /// Creates the supplier map view.
  const SupplierMapView({super.key, this.tileProvider});

  /// Optional custom tile provider (useful for tests and offline fixtures).
  final TileProvider? tileProvider;

  @override
  ConsumerState<SupplierMapView> createState() => _SupplierMapViewState();
}

class _SupplierMapViewState extends ConsumerState<SupplierMapView> {
  final MapController _mapController = MapController();

  static const _defaultCenter = LatLng(6.9271, 79.8612); // Colombo

  @override
  Widget build(BuildContext context) {
    final colors = context.ag;
    final suppliers = ref.watch(sortedSuppliersProvider);
    final userPos = ref.watch(currentPositionProvider).valueOrNull;

    final center = userPos != null
        ? LatLng(userPos.latitude, userPos.longitude)
        : _defaultCenter;

    final supplierMarkers = suppliers.map((supplier) {
      return Marker(
        point: LatLng(supplier.latitude, supplier.longitude),
        width: kMinTouchTarget,
        height: kMinTouchTarget,
        child: Semantics(
          label: supplier.name,
          button: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              SupplierPinModal.show(
                context,
                supplier: supplier,
                userLatitude: userPos?.latitude,
                userLongitude: userPos?.longitude,
              );
            },
            child: Container(
              padding: const EdgeInsets.all(AgSpace.s8),
              decoration: BoxDecoration(
                color: colors.brand,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors.text.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.storefront,
                size: 20,
                color: colors.onDark,
              ),
            ),
          ),
        ),
      );
    }).toList();

    Marker? userMarker;
    if (userPos != null) {
      userMarker = Marker(
        point: LatLng(userPos.latitude, userPos.longitude),
        width: 32,
        height: 32,
        child: Semantics(
          label: 'Your current location',
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.text,
              border: Border.all(color: colors.surface, width: 3),
            ),
            child: Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.brand,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        Container(
          color: colors.subtle,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 12.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.futurix.aquagrow',
                tileProvider: widget.tileProvider,
              ),
              MarkerLayer(
                markers: [
                  ...supplierMarkers,
                  if (userMarker != null) userMarker,
                ],
              ),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          bottom: AgSpace.s8,
          left: AgSpace.s12,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AgSpace.s8,
              vertical: AgSpace.s4,
            ),
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.9),
              borderRadius: AgRadius.all(AgRadius.r16),
              border: Border.all(color: colors.border),
            ),
            child: Text(
              'Map tiles need internet. The list still works.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
          ),
        ),
        Positioned(
          top: AgSpace.s12,
          right: AgSpace.s12,
          child: FloatingActionButton.small(
            tooltip: userPos != null ? 'Centre on me' : 'Centre on Colombo',
            backgroundColor: colors.surface,
            foregroundColor: colors.text,
            onPressed: () {
              _mapController.move(center, 13.0);
            },
            child: const Icon(Icons.my_location, size: 20),
          ),
        ),
      ],
    );
  }
}
