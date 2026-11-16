import 'package:aquagrow_mobile/core/interfaces/i_launcher_service.dart';
import 'package:aquagrow_mobile/core/models/hydro_supplier.dart';
import 'package:aquagrow_mobile/core/theme/app_theme.dart';
import 'package:aquagrow_mobile/features/location/application/location_providers.dart';
import 'package:aquagrow_mobile/features/location/presentation/widgets/supplier_pin_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeLauncherService implements ILauncherService {
  FakeLauncherService({
    this.dialResult = true,
    this.directionsResult = true,
  });

  bool dialResult;
  bool directionsResult;

  String? dialedPhone;
  double? launchedLat;
  double? launchedLng;
  String? launchedLabel;

  @override
  Future<bool> dial(String phone) async {
    dialedPhone = phone;
    return dialResult;
  }

  @override
  Future<bool> openDirections({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    launchedLat = latitude;
    launchedLng = longitude;
    launchedLabel = label;
    return directionsResult;
  }
}

void main() {
  const testSupplier = HydroSupplier(
    id: 'sup_test_1',
    name: 'Colombo Hydroponics',
    category: 'Nutrients & Seedlings',
    address: '123 Galle Road, Colombo 03',
    city: 'Colombo',
    phone: '+94 11 234 5678',
    latitude: 6.9012,
    longitude: 79.8529,
    rating: 4.8,
    openHours: '8:30 AM - 5:30 PM',
    featuredProducts: ['MasterBlend', 'Rockwool', 'pH Down'],
    isVerified: true,
  );

  Widget buildSubject({required FakeLauncherService launcher}) {
    return ProviderScope(
      overrides: [
        launcherServiceProvider.overrideWithValue(launcher),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: SupplierPinModal(
            supplier: testSupplier,
            userLatitude: 6.9271,
            userLongitude: 79.8612,
          ),
        ),
      ),
    );
  }

  testWidgets('tapping Call invokes dial with supplier phone number',
      (tester) async {
    final launcher = FakeLauncherService(dialResult: true);
    await tester.pumpWidget(buildSubject(launcher: launcher));
    await tester.pump();

    await tester.tap(find.text(testSupplier.phone));
    await tester.pumpAndSettle();

    expect(launcher.dialedPhone, testSupplier.phone);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('failed Call shows fallback snackbar with copy action',
      (tester) async {
    final launcher = FakeLauncherService(dialResult: false);
    await tester.pumpWidget(buildSubject(launcher: launcher));
    await tester.pump();

    await tester.tap(find.text(testSupplier.phone));
    await tester.pumpAndSettle();

    expect(find.text('Could not open the phone app'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
  });

  testWidgets(
      'tapping Directions invokes openDirections with coordinates and label',
      (tester) async {
    final launcher = FakeLauncherService(directionsResult: true);
    await tester.pumpWidget(buildSubject(launcher: launcher));
    await tester.pump();

    await tester.tap(find.text('Directions'));
    await tester.pumpAndSettle();

    expect(launcher.launchedLat, testSupplier.latitude);
    expect(launcher.launchedLng, testSupplier.longitude);
    expect(launcher.launchedLabel, testSupplier.name);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('failed Directions shows fallback snackbar with copy action',
      (tester) async {
    final launcher = FakeLauncherService(directionsResult: false);
    await tester.pumpWidget(buildSubject(launcher: launcher));
    await tester.pump();

    await tester.tap(find.text('Directions'));
    await tester.pumpAndSettle();

    expect(find.text('Could not open maps'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
  });
}
