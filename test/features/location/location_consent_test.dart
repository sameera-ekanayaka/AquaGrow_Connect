import 'package:aquagrow_mobile/core/services/geo_service.dart';
import 'package:aquagrow_mobile/features/location/domain/location_access_status.dart';
import 'package:aquagrow_mobile/features/location/presentation/location_providers.dart';
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

    test(
        'when consent is granted, queries GPS service and yields live position',
        () async {
      final fakeGeo = FakeGeoService.granted(
        latitude: 7.2906,
        longitude: 80.6337,
      );

      final container = ProviderContainer(
        overrides: [
          geoServiceProvider.overrideWithValue(fakeGeo),
        ],
      );
      addTearDown(container.dispose);

      container.read(locationConsentProvider.notifier).state = true;
      final result = await container.read(locationResultProvider.future);

      expect(result.status, equals(LocationAccessStatus.granted));
      expect(result.isFallback, isFalse);
      expect(result.position.latitude, equals(7.2906));
    });
  });
}
