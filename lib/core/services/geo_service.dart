import 'package:flutter/foundation.dart';
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

/// Service managing hardware GPS coordinate acquisition, runtime permissions,
/// and fallback coordinates for academic viva demonstrations.
class GeoService {
  GeoPosition? _mockOverridePosition;

  /// Injects a fixed geographic coordinate for automated testing or viva demo.
  void setMockLocation(GeoPosition? position) {
    _mockOverridePosition = position;
  }

  /// Determines the current position of the device.
  /// When location services are unavailable, permission is denied, or running in an
  /// emulator, safely falls back to default Colombo coordinates without throwing.
  Future<GeoPosition> getCurrentPosition() async {
    if (_mockOverridePosition != null) {
      return _mockOverridePosition!;
    }

    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[GeoService] Location services disabled on device. Using Colombo default.');
        return GeoPosition.defaultColombo;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('[GeoService] Location permission denied. Using Colombo default.');
          return GeoPosition.defaultColombo;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('[GeoService] Location permission permanently denied. Using Colombo default.');
        return GeoPosition.defaultColombo;
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );

      return GeoPosition(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
        isSimulated: position.isMocked,
        locationSource: position.isMocked ? 'Mock GPS Provider' : 'Hardware GPS Sensor',
      );
    } catch (e) {
      debugPrint('[GeoService] Error acquiring location: $e. Falling back to default.');
      return GeoPosition.defaultColombo;
    }
  }

  /// Computes distance in kilometers between two geographic coordinate points.
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
