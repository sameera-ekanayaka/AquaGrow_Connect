import 'package:aquagrow_mobile/core/services/geo_service.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/features/location/application/location_providers.dart';
import 'package:aquagrow_mobile/features/location/domain/location_access_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_geo_service.dart';

void main() {
  group('locationConsentProvider & locationResultProvider', () {
    test('defaults to false and returns Colombo fallback without querying GPS',
        () async {
      var queried = false;
      final fakeGeo = FakeGeoService.granted(
        latitude: 7.2906,
        longitude: 80.6337,
      );

      final container = ProviderContainer(
        overrides: [
          geoServiceProvider.overrideWith((ref) {
            queried = true;
            return fakeGeo;
          }),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(locationConsentProvider), isFalse);

      final result = await container.read(locationResultProvider.future);
      expect(result.status, equals(LocationAccessStatus.denied));
      expect(result.isFallback, isTrue);
      expect(
        result.position.latitude,
        equals(GeoPosition.defaultColombo.latitude),
      );
      expect(queried, isFalse);
    });

    test('initializes consent from preferencesStoreProvider surviving restarts',
        () async {
      final fakeGeo = FakeGeoService.granted(
        latitude: 7.2906,
        longitude: 80.6337,
      );

      final container1 = ProviderContainer(
        overrides: [
          geoServiceProvider.overrideWithValue(fakeGeo),
        ],
      );
      addTearDown(container1.dispose);

      // User grants consent and preference is stored
      container1.read(locationConsentProvider.notifier).state = true;
      final prefs = container1.read(preferencesStoreProvider);
      await prefs.setBool(kLocationConsentPrefKey, value: true);

      // Simulate app restart with a fresh container sharing the same preferences store
      final container2 = ProviderContainer(
        overrides: [
          preferencesStoreProvider.overrideWithValue(prefs),
          geoServiceProvider.overrideWithValue(fakeGeo),
        ],
      );
      addTearDown(container2.dispose);

      expect(container2.read(locationConsentProvider), isTrue);
      final result = await container2.read(locationResultProvider.future);
      expect(result.status, equals(LocationAccessStatus.granted));
      expect(result.position.latitude, equals(7.2906));
    });
  });
}
