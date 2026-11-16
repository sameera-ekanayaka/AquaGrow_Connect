import 'dart:typed_data';

import 'package:aquagrow_mobile/core/models/hydro_supplier.dart';
import 'package:aquagrow_mobile/core/services/geo_service.dart';
import 'package:aquagrow_mobile/core/theme/app_theme.dart';
import 'package:aquagrow_mobile/features/location/application/location_providers.dart';
import 'package:aquagrow_mobile/features/location/presentation/widgets/supplier_map_view.dart';
import 'package:aquagrow_mobile/features/location/presentation/widgets/supplier_pin_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return MemoryImage(
      Uint8List.fromList([
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
        0x00,
        0x00,
        0x00,
        0x0D,
        0x49,
        0x48,
        0x44,
        0x52,
        0x00,
        0x00,
        0x00,
        0x01,
        0x00,
        0x00,
        0x00,
        0x01,
        0x08,
        0x06,
        0x00,
        0x00,
        0x00,
        0x1F,
        0x15,
        0xC4,
        0x89,
        0x00,
        0x00,
        0x00,
        0x0A,
        0x49,
        0x44,
        0x41,
        0x54,
        0x78,
        0x9C,
        0x63,
        0x00,
        0x01,
        0x00,
        0x00,
        0x05,
        0x00,
        0x01,
        0x0D,
        0x0A,
        0x2D,
        0xB4,
        0x00,
        0x00,
        0x00,
        0x00,
        0x49,
        0x45,
        0x4E,
        0x44,
        0xAE,
        0x42,
        0x60,
        0x82,
      ]),
    );
  }
}

const _mockSuppliers = [
  HydroSupplier(
    id: 's1',
    name: 'Colombo Hydro Store',
    category: 'Nutrients',
    address: '1 Galle Rd',
    city: 'Colombo',
    latitude: 6.91,
    longitude: 79.86,
    phone: '0112345678',
    rating: 4.5,
    openHours: '9am - 5pm',
    featuredProducts: ['Rockwool'],
    isVerified: true,
  ),
  HydroSupplier(
    id: 's2',
    name: 'Colombo Hydro Depot',
    category: 'Grow Lights',
    address: '2 Baseline Rd',
    city: 'Colombo',
    latitude: 6.93,
    longitude: 79.87,
    phone: '0119876543',
    rating: 4.8,
    openHours: '8am - 4pm',
    featuredProducts: ['LED 50W'],
    isVerified: true,
  ),
];

void main() {
  Widget buildSubject({
    List<HydroSupplier> suppliers = _mockSuppliers,
    GeoPosition? userPos,
  }) {
    return ProviderScope(
      overrides: [
        sortedSuppliersProvider.overrideWithValue(suppliers),
        currentPositionProvider.overrideWith(
          (ref) => userPos != null
              ? Future.value(userPos)
              : Future<GeoPosition>.error('No GPS'),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SupplierMapView(
            tileProvider: _TestTileProvider(),
          ),
        ),
      ),
    );
  }

  testWidgets('renders FlutterMap, markers, and OpenStreetMap attribution',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(RichAttributionWidget), findsOneWidget);
    expect(find.byTooltip('Centre on Colombo'), findsOneWidget);
    expect(
      find.text('Map tiles need internet. The list still works.'),
      findsOneWidget,
    );

    // One marker per supplier
    expect(find.byIcon(Icons.storefront), findsNWidgets(2));
  });

  testWidgets('shows user location dot when position is available',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const userPos = GeoPosition(latitude: 6.9271, longitude: 79.8612);
    await tester.pumpWidget(buildSubject(userPos: userPos));
    await tester.pump();

    expect(find.byTooltip('Centre on me'), findsOneWidget);
    expect(find.bySemanticsLabel('Your current location'), findsOneWidget);
  });

  testWidgets('tapping a supplier pin opens SupplierPinModal', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSubject());
    await tester.pump();

    await tester.tap(find.byIcon(Icons.storefront).first);
    await tester.pumpAndSettle();

    expect(find.byType(SupplierPinModal), findsOneWidget);
    expect(find.text('Colombo Hydro Store'), findsOneWidget);
  });
}
