import 'package:aquagrow_mobile/core/services/geo_service.dart';
import 'package:aquagrow_mobile/core/theme/app_theme.dart';
import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/features/location/application/location_providers.dart';
import 'package:aquagrow_mobile/features/location/domain/location_access_status.dart';
import 'package:aquagrow_mobile/features/location/presentation/widgets/location_status_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_geo_service.dart';

void main() {
  Widget buildBanner(LocationResult result, [ProviderContainer? container]) {
    final c = container ??
        ProviderContainer(
          overrides: [
            geoServiceProvider.overrideWithValue(
              FakeGeoService(result: result),
            ),
            locationResultProvider.overrideWith((ref) => Future.value(result)),
          ],
        );

    return UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: LocationStatusBanner(result: result),
        ),
      ),
    );
  }

  group('LocationStatusBanner widget tests', () {
    testWidgets('renders nothing when location is granted', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final result = LocationResult.granted(
        const GeoPosition(latitude: 6.9271, longitude: 79.8612),
      );
      await tester.pumpWidget(buildBanner(result));
      await tester.pump();

      expect(find.text('Try again'), findsNothing);
      expect(find.text('Open settings'), findsNothing);
      expect(find.text('Enable GPS'), findsNothing);
    });

    testWidgets('shows Use my location button when permission is denied',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final result = LocationResult.denied();
      await tester.pumpWidget(buildBanner(result));
      await tester.pump();

      expect(find.text('Use my location'), findsOneWidget);
      expect(find.textContaining('Colombo'), findsOneWidget);

      final btnSize = tester.getSize(find.byType(TextButton));
      expect(btnSize.height, greaterThanOrEqualTo(kMinTouchTarget));
    });

    testWidgets('tapping Use my location shows LocationRationaleDialog',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final result = LocationResult.denied();
      await tester.pumpWidget(buildBanner(result));
      await tester.pump();

      await tester.tap(find.text('Use my location'));
      await tester.pumpAndSettle();

      expect(find.text('Allow Location Access'), findsOneWidget);
    });

    testWidgets('shows Open settings button when permanently denied',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final result = LocationResult.permanentlyDenied();
      await tester.pumpWidget(buildBanner(result));
      await tester.pump();

      expect(find.text('Open settings'), findsOneWidget);
      expect(
        find.textContaining('Location permanently denied'),
        findsOneWidget,
      );
    });

    testWidgets('shows Enable GPS button when service is disabled',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final result = LocationResult.serviceDisabled();
      await tester.pumpWidget(buildBanner(result));
      await tester.pump();

      expect(find.text('Enable GPS'), findsOneWidget);
      expect(
        find.textContaining('Device GPS is off'),
        findsOneWidget,
      );
    });
  });
}
