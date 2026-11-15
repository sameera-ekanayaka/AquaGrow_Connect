import 'package:aquagrow_mobile/core/interfaces/i_geo_service.dart';
import 'package:aquagrow_mobile/core/services/geo_service.dart';
import 'package:aquagrow_mobile/features/location/domain/location_access_status.dart';

/// Test double for [IGeoService] that returns a predetermined [LocationResult]
/// without touching the geolocator plugin.
///
/// Inject via Riverpod `overrideWith` in widget tests or unit tests.
class FakeGeoService implements IGeoService {
  /// Creates a [FakeGeoService] with the given canned [result].
  FakeGeoService({required this.result});

  /// The [LocationResult] returned by every [getPosition] call.
  final LocationResult result;

  @override
  Future<LocationResult> getPosition() async => result;

  @override
  double distanceBetween({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    // Approximate Haversine for test use — avoids geolocator plugin.
    const r = 6371.0;
    final dLat = _toRad(endLatitude - startLatitude);
    final dLon = _toRad(endLongitude - startLongitude);
    final a = _sin2(dLat / 2) +
        _cos(_toRad(startLatitude)) *
            _cos(_toRad(endLatitude)) *
            _sin2(dLon / 2);
    return 2 * r * _asin(a < 0 ? 0 : (a > 1 ? 1 : _sqrt(a)));
  }

  static double _toRad(double deg) => deg * 3.141592653589793 / 180;
  static double _sin2(double x) => _sin(x) * _sin(x);

  // Minimal pure-Dart trig (avoids dart:math import in production fakes).
  static double _sin(double x) {
    // Taylor series — sufficient for the small angles in distance calculations.
    double result = x;
    double term = x;
    for (int n = 1; n <= 8; n++) {
      term *= -x * x / ((2 * n) * (2 * n + 1));
      result += term;
    }
    return result;
  }

  static double _cos(double x) => _sin(3.141592653589793 / 2 - x);

  static double _sqrt(double x) {
    if (x == 0) return 0;
    double r = x;
    for (int i = 0; i < 20; i++) {
      r = (r + x / r) / 2;
    }
    return r;
  }

  static double _asin(double x) {
    // atan2 approximation adequate for unit-test distance checks.
    return x + x * x * x / 6 + 3 * x * x * x * x * x / 40;
  }

  /// Convenience constructor for a granted result at a custom position.
  factory FakeGeoService.granted({
    double latitude = 6.9271,
    double longitude = 79.8612,
  }) =>
      FakeGeoService(
        result: LocationResult.granted(
          GeoPosition(latitude: latitude, longitude: longitude),
        ),
      );

  /// Convenience constructor for a denied fallback result.
  factory FakeGeoService.denied() =>
      FakeGeoService(result: LocationResult.denied());

  /// Convenience constructor for a permanently denied fallback result.
  factory FakeGeoService.permanentlyDenied() =>
      FakeGeoService(result: LocationResult.permanentlyDenied());

  /// Convenience constructor for a service-disabled fallback result.
  factory FakeGeoService.serviceDisabled() =>
      FakeGeoService(result: LocationResult.serviceDisabled());
}
