import 'package:aquagrow_mobile/features/location/domain/location_access_status.dart';

/// Abstract contract for hardware GPS and geolocation access.
///
/// Separating the interface from [GeoService] enables injection of
/// [FakeGeoService] in tests without touching the geolocator plugin.
abstract interface class IGeoService {
  /// Acquires the current device position, including permission state.
  ///
  /// Always resolves — never throws. Falls back to Colombo coordinates when
  /// permission is denied or GPS hardware is unavailable.
  Future<LocationResult> getPosition();

  /// Computes the distance in kilometres between two coordinate pairs.
  double distanceBetween({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  });
}
