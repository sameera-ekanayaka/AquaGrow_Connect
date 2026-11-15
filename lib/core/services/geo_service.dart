import 'package:aquagrow_mobile/core/interfaces/i_geo_service.dart';
import 'package:aquagrow_mobile/core/logging/app_logger.dart';
import 'package:aquagrow_mobile/features/location/domain/location_access_status.dart';
import 'package:geolocator/geolocator.dart';

/// Structured GPS coordinate model with location source metadata.
class GeoPosition {
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final bool isSimulated;
  final String locationSource;

  const GeoPosition({
    required this.latitude,
    required this.longitude,
    this.accuracyMeters = 10.0,
    this.isSimulated = false,
    this.locationSource = 'Device GPS',
  });

  /// Default fallback geographic location: Colombo, Western Province, Sri Lanka.
  static const GeoPosition defaultColombo = GeoPosition(
    latitude: 6.9271,
    longitude: 79.8612,
    accuracyMeters: 25.0,
    isSimulated: true,
    locationSource: 'Fallback Default (Colombo)',
  );

  /// Default fallback location: Kandy, Central Province, Sri Lanka.
  static const GeoPosition defaultKandy = GeoPosition(
    latitude: 7.2906,
    longitude: 80.6337,
    accuracyMeters: 25.0,
    isSimulated: true,
    locationSource: 'Fallback Default (Kandy)',
  );

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'accuracyMeters': accuracyMeters,
        'isSimulated': isSimulated,
        'locationSource': locationSource,
      };
}

/// Hardware GPS service implementing [IGeoService].
///
/// Requests runtime location permissions, handles all denial states, and
/// always returns a [LocationResult] — never throwing. When permission is
/// denied or GPS is unavailable the result carries Colombo fallback coordinates
/// and a human-readable [LocationResult.fallbackReason].
class GeoService implements IGeoService {
  static const _log = AppLogger('location');

  LocationResult? _mockOverrideResult;

  /// Injects a fixed [LocationResult] for automated testing or viva demo.
  void setMockResult(LocationResult? result) {
    _mockOverrideResult = result;
  }

  /// Injects a fixed geographic coordinate for backward compatibility.
  void setMockLocation(GeoPosition? position) {
    _mockOverrideResult =
        position == null ? null : LocationResult.granted(position);
  }

  /// Backward-compatible coordinate acquisition returning raw [GeoPosition].
  Future<GeoPosition> getCurrentPosition() async {
    final result = await getPosition();
    return result.position;
  }

  @override
  Future<LocationResult> getPosition() async {
    if (_mockOverrideResult != null) {
      return _mockOverrideResult!;
    }

    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _log.warning('Location services disabled on device.');
        return LocationResult.serviceDisabled();
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _log.warning('Location permission denied by user.');
          return LocationResult.denied();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _log.warning('Location permission permanently denied.');
        return LocationResult.permanentlyDenied();
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );

      final geoPos = GeoPosition(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
        isSimulated: position.isMocked,
        locationSource:
            position.isMocked ? 'Mock GPS Provider' : 'Hardware GPS Sensor',
      );

      return LocationResult.granted(geoPos);
    } catch (e) {
      _log.error('Error acquiring location: $e. Falling back to default.');
      return LocationResult.denied(
        reason: 'GPS signal timed out. Showing Colombo weather.',
      );
    }
  }

  @override
  double distanceBetween({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    final double distanceInMeters = Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
    return distanceInMeters / 1000.0;
  }
}
