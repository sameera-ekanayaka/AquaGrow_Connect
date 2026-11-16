import 'package:aquagrow_mobile/core/interfaces/i_launcher_service.dart';
import 'package:aquagrow_mobile/core/models/hydro_supplier.dart';
import 'package:aquagrow_mobile/core/theme/app_theme.dart';
import 'package:aquagrow_mobile/features/location/application/location_providers.dart';
import 'package:aquagrow_mobile/features/location/presentation/widgets/supplier_pin_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeLauncher implements ILauncherService {
  _FakeLauncher({this.success = true});
  final bool success;
  String? lastPhone;
  bool directionsCalled = false;

  @override
  Future<bool> dial(String phone) async {
    lastPhone = phone;
    return success;
  }

  @override
  Future<bool> openDirections({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    directionsCalled = true;
    return success;
  }
}

/// A verified test supplier used across all modal tests.
const _verifiedSupplier = HydroSupplier(
  id: 'sup-t-01',
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
  featuredProducts: [
    'MasterBlend 4-18-38 Complete',
    'Calcium Nitrate Fertilizer',
    'Magnesium Sulfate (Epsom)',
  ],
);

/// An unverified test supplier for badge-absence tests.
const _unverifiedSupplier = HydroSupplier(
  id: 'sup-t-02',
  name: 'Budget Hydro Store',
  category: 'Seeds & Genetics',
  address: '5 Garden Road, Kandy',
  city: 'Kandy',
  latitude: 7.288,
  longitude: 80.627,
  phone: '+94 81 223 0000',
  rating: 3.5,
  openHours: '10:00 AM - 05:00 PM',
  isVerified: false,
  featuredProducts: ['Basil Seeds', 'Spinach Seeds'],
);

/// Pumps [SupplierPinModal] directly into a [MaterialApp] for testing.
Widget _buildModal({
  HydroSupplier supplier = _verifiedSupplier,
  double? userLatitude,
  double? userLongitude,
  ILauncherService? launcher,
}) {
  return ProviderScope(
    overrides: [
      if (launcher != null)
        launcherServiceProvider.overrideWithValue(launcher),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SupplierPinModal(
          supplier: supplier,
          userLatitude: userLatitude,
          userLongitude: userLongitude,
        ),
      ),
    ),
  );
}

void main() {
  group('SupplierPinModal widget tests', () {
    testWidgets('shows supplier name', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildModal());
      await tester.pump();

      expect(find.text('Lanka Hydroponics Hub'), findsOneWidget);
    });

    testWidgets('shows category and city', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildModal());
      await tester.pump();

      expect(
        find.text('Nutrients & Buffers • Colombo'),
        findsOneWidget,
      );
    });

    testWidgets('shows address', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildModal());
      await tester.pump();

      expect(
        find.text('No. 142, High Level Road, Nugegoda'),
        findsOneWidget,
      );
    });

    testWidgets('shows phone number', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildModal());
      await tester.pump();

      expect(find.text('+94 11 282 4500'), findsOneWidget);
    });

    testWidgets('shows rating', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildModal());
      await tester.pump();

      expect(find.textContaining('4.8'), findsOneWidget);
    });

    testWidgets('shows open hours', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildModal());
      await tester.pump();

      expect(find.text('08:30 AM - 06:00 PM'), findsOneWidget);
    });

    testWidgets('shows verified icon when isVerified is true', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildModal());
      await tester.pump();

      expect(find.byIcon(Icons.verified), findsOneWidget);
    });

    testWidgets('does not show verified icon when isVerified is false',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildModal(supplier: _unverifiedSupplier));
      await tester.pump();

      expect(find.byIcon(Icons.verified), findsNothing);
    });

    testWidgets(
        'shows distance badge when userLatitude and userLongitude provided',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _buildModal(userLatitude: 6.9271, userLongitude: 79.8612),
      );
      await tester.pump();

      // Distance from Colombo (6.9271, 79.8612) to supplier (6.871, 79.897) is ~8 km.
      expect(find.textContaining('km'), findsOneWidget);
    });

    testWidgets('does not show distance badge when user coords are null',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildModal());
      await tester.pump();

      expect(find.textContaining('km'), findsNothing);
    });

    testWidgets('shows all featured product inventory badges', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildModal());
      await tester.pump();

      expect(find.text('MasterBlend 4-18-38 Complete'), findsOneWidget);
      expect(find.text('Calcium Nitrate Fertilizer'), findsOneWidget);
      expect(find.text('Magnesium Sulfate (Epsom)'), findsOneWidget);
    });

    testWidgets('shows Call button with phone number label', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildModal());
      await tester.pump();

      expect(find.byIcon(Icons.phone), findsOneWidget);
      // The phone number appears as the button label text.
      expect(find.text('+94 11 282 4500'), findsOneWidget);
    });

    testWidgets('shows Directions button', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildModal());
      await tester.pump();

      expect(find.byIcon(Icons.directions), findsOneWidget);
      expect(find.text('Directions'), findsOneWidget);
    });

    testWidgets('tapping Call invokes launcher dial', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final launcher = _FakeLauncher(success: true);
      await tester.pumpWidget(_buildModal(launcher: launcher));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.phone));
      await tester.pumpAndSettle();

      expect(launcher.lastPhone, _verifiedSupplier.phone);
    });

    testWidgets('tapping Directions invokes launcher openDirections', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final launcher = _FakeLauncher(success: true);
      await tester.pumpWidget(_buildModal(launcher: launcher));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.directions));
      await tester.pumpAndSettle();

      expect(launcher.directionsCalled, isTrue);
    });

    testWidgets('shows inventory section header', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildModal());
      await tester.pump();

      expect(
        find.text('Verified In-Stock Hydroponic Inventory'),
        findsOneWidget,
      );
    });
  });
}
