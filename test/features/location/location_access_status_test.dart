import 'package:aquagrow_mobile/core/services/geo_service.dart';
import 'package:aquagrow_mobile/features/location/domain/location_access_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocationAccessStatus & LocationResult tests', () {
    test('granted factory creates non-fallback result', () {
      const livePos = GeoPosition(
        latitude: 7.2906,
        longitude: 80.6337,
        locationSource: 'Device GPS',
      );
      final result = LocationResult.granted(livePos);

      expect(result.status, equals(LocationAccessStatus.granted));
      expect(result.isFallback, isFalse);
      expect(result.position.latitude, equals(7.2906));
      expect(result.fallbackReason, isNull);
    });

    test('denied factory returns Colombo with fallback flag and note', () {
      final result = LocationResult.denied();

      expect(result.status, equals(LocationAccessStatus.denied));
      expect(result.isFallback, isTrue);
      expect(
        result.position.latitude,
        equals(GeoPosition.defaultColombo.latitude),
      );
      expect(result.fallbackReason, contains('Colombo'));
    });

    test('permanentlyDenied factory returns Colombo and prompts settings', () {
      final result = LocationResult.permanentlyDenied();

      expect(result.status, equals(LocationAccessStatus.permanentlyDenied));
      expect(result.isFallback, isTrue);
      expect(
        result.position.latitude,
        equals(GeoPosition.defaultColombo.latitude),
      );
      expect(result.fallbackReason, contains('settings'));
    });

    test('serviceDisabled factory returns Colombo and flags GPS disabled', () {
      final result = LocationResult.serviceDisabled();

      expect(result.status, equals(LocationAccessStatus.serviceDisabled));
      expect(result.isFallback, isTrue);
      expect(
        result.position.latitude,
        equals(GeoPosition.defaultColombo.latitude),
      );
      expect(result.fallbackReason, contains('GPS'));
    });
  });
}
