import 'package:aquagrow_mobile/core/services/geo_service.dart';

/// Status classification of hardware location services and runtime permissions.
enum LocationAccessStatus {
  /// Location access is fully granted and hardware GPS is active.
  granted,

  /// Location permission was denied by the user. User can be prompted to try again.
  denied,

  /// Location permission is permanently denied in system settings.
  permanentlyDenied,

  /// Hardware location services (GPS) are disabled at the system level.
  serviceDisabled,
}

/// Structured outcome of a location acquisition attempt including fallback metadata.
class LocationResult {
  const LocationResult({
    required this.position,
    required this.status,
    this.fallbackReason,
  });

  /// Resulting geographic coordinates (either live GPS or Colombo fallback).
  final GeoPosition position;

  /// Hardware and permission status at time of acquisition.
  final LocationAccessStatus status;

  /// Human-readable explanation if a fallback location was utilized.
  final String? fallbackReason;

  /// Whether the returned coordinates represent a fallback location.
  bool get isFallback => status != LocationAccessStatus.granted;

  /// Factory helper for successful GPS acquisition.
  factory LocationResult.granted(GeoPosition position) => LocationResult(
        position: position,
        status: LocationAccessStatus.granted,
      );

  /// Factory helper for denied permission fallback.
  factory LocationResult.denied({String? reason}) => LocationResult(
        position: GeoPosition.defaultColombo,
        status: LocationAccessStatus.denied,
        fallbackReason:
            reason ?? 'Location permission denied. Showing Colombo weather.',
      );

  /// Factory helper for permanently denied permission fallback.
  factory LocationResult.permanentlyDenied({String? reason}) => LocationResult(
        position: GeoPosition.defaultColombo,
        status: LocationAccessStatus.permanentlyDenied,
        fallbackReason:
            reason ?? 'Location permanently denied. Enable it in app settings.',
      );

  /// Factory helper for disabled GPS service fallback.
  factory LocationResult.serviceDisabled({String? reason}) => LocationResult(
        position: GeoPosition.defaultColombo,
        status: LocationAccessStatus.serviceDisabled,
        fallbackReason: reason ?? 'Device GPS is off. Showing Colombo weather.',
      );
}
