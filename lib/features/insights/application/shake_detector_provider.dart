import 'package:aquagrow_mobile/features/insights/domain/shake_detector_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Provides configuration parameters for shake detection in the Insights feature.
///
/// OWNER: Imasha (see docs/tasks/imasha.md).
final shakeDetectorConfigProvider = Provider<ShakeDetectorConfig>((ref) {
  return const ShakeDetectorConfig();
});

/// Provides an optional custom accelerometer stream (used for injecting test doubles).
///
/// If null, [ShakeDetector] falls back to live hardware sensors.
final shakeDetectorStreamProvider =
    Provider<Stream<AccelerometerEvent>?>((ref) => null);

/// Provides the clock function used for throttling shake events.
final shakeDetectorClockProvider = Provider<DateTime Function()>((ref) {
  return DateTime.now;
});
