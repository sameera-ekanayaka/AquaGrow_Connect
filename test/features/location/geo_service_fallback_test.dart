import 'package:aquagrow_mobile/core/services/geo_service.dart';
import 'package:aquagrow_mobile/features/location/domain/location_access_status.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_geo_service.dart';

void main() {
  group('FakeGeoService — permission state fallback tests', () {
    test('granted result carries live position and isFallback = false',
        () async {
      final fake = FakeGeoService.granted(latitude: 7.2906, longitude: 80.6337);
      final result = await fake.getPosition();

      expect(result.status, equals(LocationAccessStatus.granted));
      expect(result.isFallback, isFalse);
      expect(result.position.latitude, equals(7.2906));
      expect(result.fallbackReason, isNull);
    });

    test('denied result falls back to Colombo and isFallback = true', () async {
      final fake = FakeGeoService.denied();
      final result = await fake.getPosition();

      expect(result.status, equals(LocationAccessStatus.denied));
      expect(result.isFallback, isTrue);
      expect(
        result.position.latitude,
        equals(GeoPosition.defaultColombo.latitude),
      );
      expect(result.fallbackReason, contains('Colombo'));
    });

    test('permanentlyDenied result points to settings in fallback note',
        () async {
      final fake = FakeGeoService.permanentlyDenied();
      final result = await fake.getPosition();

      expect(result.status, equals(LocationAccessStatus.permanentlyDenied));
      expect(result.isFallback, isTrue);
      expect(
        result.position.latitude,
        equals(GeoPosition.defaultColombo.latitude),
      );
      expect(result.fallbackReason, contains('settings'));
    });

    test('serviceDisabled result mentions GPS in fallback note', () async {
      final fake = FakeGeoService.serviceDisabled();
      final result = await fake.getPosition();

      expect(result.status, equals(LocationAccessStatus.serviceDisabled));
      expect(result.isFallback, isTrue);
      expect(
        result.position.latitude,
        equals(GeoPosition.defaultColombo.latitude),
      );
      expect(result.fallbackReason, contains('GPS'));
    });

    test('custom LocationResult passthrough works for arbitrary results',
        () async {
      const customPos = GeoPosition(
        latitude: 1.23,
        longitude: 4.56,
        locationSource: 'Test',
      );
      final fake = FakeGeoService(
        result: const LocationResult(
          position: customPos,
          status: LocationAccessStatus.granted,
        ),
      );
      final result = await fake.getPosition();

      expect(result.position.latitude, equals(1.23));
      expect(result.isFallback, isFalse);
    });
  });
}
