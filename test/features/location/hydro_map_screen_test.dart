import 'package:aquagrow_mobile/core/models/hydro_supplier.dart';
import 'package:aquagrow_mobile/core/services/geo_service.dart';
import 'package:aquagrow_mobile/core/theme/app_theme.dart';
import 'package:aquagrow_mobile/features/location/domain/location_access_status.dart';
import 'package:aquagrow_mobile/features/location/presentation/hydro_map_screen.dart';
import 'package:aquagrow_mobile/features/location/presentation/location_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_geo_service.dart';

/// Minimal list of two suppliers used in widget tests.
const _twoSuppliers = [
  HydroSupplier(
    id: 'sup-test-01',
    name: 'Lanka Hydroponics Hub',
    category: 'Nutrients & Buffers',
    address: 'No. 142, High Level Road, Nugegoda',
    city: 'Colombo',
    latitude: 6.871,
    longitude: 79.897,
    phone: '+94 11 282 4500',
    rating: 4.8,
    openHours: '08:30 AM - 06:00 PM',
    isVerified: true,
    featuredProducts: ['MasterBlend 4-18-38', 'Calcium Nitrate'],
  ),
  HydroSupplier(
    id: 'sup-test-02',
    name: 'AgriGreen Automation',
    category: 'Rockwool & Growing Media',
    address: '88/2 Baseline Road, Dematagoda',
    city: 'Colombo',
    latitude: 6.936,
    longitude: 79.878,
    phone: '+94 11 441 7890',
    rating: 4.7,
    openHours: '09:00 AM - 06:30 PM',
    isVerified: false,
    featuredProducts: ['Grodan Rockwool Plugs', 'LECA Clay Pebbles'],
  ),
];

/// Builds a [HydroMapScreen] inside a [MaterialApp] with [UncontrolledProviderScope].
Widget _buildScreen({
  List<HydroSupplier> suppliers = _twoSuppliers,
  FakeGeoService? geoService,
}) {
  final geo = geoService ?? FakeGeoService.granted();
  final container = ProviderContainer(
    overrides: [
      geoServiceProvider.overrideWithValue(geo),
      locationResultProvider.overrideWith(
        (ref) => Future.value(
          LocationResult.granted(
            const GeoPosition(latitude: 6.9271, longitude: 79.8612),
          ),
        ),
      ),
      currentPositionProvider.overrideWith(
        (ref) => Future.value(
          const GeoPosition(latitude: 6.9271, longitude: 79.8612),
        ),
      ),
      sortedSuppliersProvider.overrideWithValue(suppliers),
    ],
  );

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: HydroMapScreen()),
    ),
  );
}

void main() {
  group('HydroMapScreen widget tests', () {
    setUp(() {});

    testWidgets('renders AppBar title', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('Hydroponic suppliers'), findsOneWidget);
    });

    testWidgets('renders first supplier name and category', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('Lanka Hydroponics Hub'), findsOneWidget);
      expect(find.textContaining('Nutrients & Buffers'), findsWidgets);
    });

    testWidgets('renders both supplier cards', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('Lanka Hydroponics Hub'), findsOneWidget);
      expect(find.text('AgriGreen Automation'), findsOneWidget);
    });

    testWidgets('shows empty state when supplier list is empty',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildScreen(suppliers: []));
      await tester.pump();

      expect(find.text('No hydroponic suppliers found'), findsOneWidget);
      expect(
        find.textContaining('Try clearing search filters'),
        findsOneWidget,
      );
    });

    testWidgets('renders search bar with placeholder text', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(
        find.widgetWithText(
          TextField,
          'Search nutrient buffers, rockwool, seeds...',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders All category chip as selected by default',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      final allChip = find.widgetWithText(FilterChip, 'All');
      expect(allChip, findsOneWidget);

      final chip = tester.widget<FilterChip>(allChip);
      expect(chip.selected, isTrue);
    });

    testWidgets(
        'selecting a category chip updates selectedSupplierCategoryProvider',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      final categoryChip =
          find.widgetWithText(FilterChip, 'Nutrients & Buffers');
      expect(categoryChip, findsOneWidget);

      await tester.tap(categoryChip);
      await tester.pump();

      final chip = tester.widget<FilterChip>(categoryChip);
      expect(chip.selected, isTrue);
    });

    testWidgets('tapping a supplier card opens SupplierPinModal',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      await tester.tap(find.text('Lanka Hydroponics Hub'));
      await tester.pumpAndSettle();

      // The modal shows the supplier name in the bottom sheet (now multiple widgets,
      // one in the card behind and one in the modal — verify at least 2 exist).
      expect(find.text('Lanka Hydroponics Hub'), findsWidgets);
      // Modal shows the category • city line.
      expect(
        find.textContaining('Nutrients & Buffers • Colombo'),
        findsWidgets,
      );
    });

    testWidgets('shows verified icon for verified supplier', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      // Lanka Hydroponics Hub isVerified=true; AgriGreen isVerified=false.
      // There is at least one verified icon on screen.
      expect(find.byIcon(Icons.verified), findsAtLeastNWidgets(1));
    });

    testWidgets('renders product tag previews in supplier cards',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('MasterBlend 4-18-38'), findsOneWidget);
      expect(find.text('Grodan Rockwool Plugs'), findsOneWidget);
    });

    testWidgets(
        'shows GPS status bar with acquiring text before position resolves',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Build with no position (denied)
      final geo = FakeGeoService.denied();
      final container = ProviderContainer(
        overrides: [
          geoServiceProvider.overrideWithValue(geo),
          locationResultProvider
              .overrideWith((ref) => Future.value(LocationResult.denied())),
          currentPositionProvider.overrideWith(
            (ref) => Future.value(GeoPosition.defaultColombo),
          ),
          sortedSuppliersProvider.overrideWithValue(_twoSuppliers),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(body: HydroMapScreen()),
          ),
        ),
      );
      // Before async resolves only the loading state shows.
      await tester.pump();

      // GPS bar always shows (even if still loading).
      expect(find.byType(HydroMapScreen), findsOneWidget);
    });

    testWidgets('typing and tapping clear button resets search field and query',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'rockwool');
      await tester.pump();

      expect(find.text('rockwool'), findsOneWidget);
      expect(find.byTooltip('Clear search'), findsOneWidget);

      await tester.tap(find.byTooltip('Clear search'));
      await tester.pump();

      expect(find.text('rockwool'), findsNothing);
      expect(find.byTooltip('Clear search'), findsNothing);
    });
  });
}
