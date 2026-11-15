import 'package:aquagrow_mobile/features/insights/domain/shake_math.dart';

/// Configuration parameters for shake gesture detection.
///
/// OWNER: Imasha (see docs/tasks/imasha.md).
class ShakeDetectorConfig {
  /// Minimum g-force required to count as a shake (default 2.7g).
  final double thresholdG;

  /// Minimum milliseconds required between consecutive shake events (default 1000ms).
  final int throttleMs;

  /// Gravitational constant used for g-force normalization in m/s^2.
  final double gravity;

  /// Creates a configuration with customizable shake thresholds and throttling.
  const ShakeDetectorConfig({
    this.thresholdG = ShakeMath.defaultShakeThresholdG,
    this.throttleMs = 1000,
    this.gravity = ShakeMath.standardGravity,
  })  : assert(thresholdG > 0, 'thresholdG must be greater than zero'),
        assert(throttleMs >= 0, 'throttleMs cannot be negative'),
        assert(gravity > 0, 'gravity must be greater than zero');

  /// Duration representing the throttle window.
  Duration get throttleDuration => Duration(milliseconds: throttleMs);

  /// Returns a copy of this config with the given fields replaced.
  ShakeDetectorConfig copyWith({
    double? thresholdG,
    int? throttleMs,
    double? gravity,
  }) {
    return ShakeDetectorConfig(
      thresholdG: thresholdG ?? this.thresholdG,
      throttleMs: throttleMs ?? this.throttleMs,
      gravity: gravity ?? this.gravity,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShakeDetectorConfig &&
        other.thresholdG == thresholdG &&
        other.throttleMs == throttleMs &&
        other.gravity == gravity;
  }

  @override
  int get hashCode => Object.hash(thresholdG, throttleMs, gravity);

  @override
  String toString() {
    return 'ShakeDetectorConfig(thresholdG: $thresholdG, throttleMs: $throttleMs, gravity: $gravity)';
  }
}
