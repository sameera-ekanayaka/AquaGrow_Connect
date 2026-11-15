import 'dart:math' as math;

/// Pure mathematical utilities for shake detection and g-force calculation.
///
/// OWNER: Imasha (see docs/tasks/imasha.md).
abstract final class ShakeMath {
  /// Standard gravitational acceleration constant in m/s^2.
  static const double standardGravity = 9.80665;

  /// Default g-force threshold to register a shake event.
  static const double defaultShakeThresholdG = 2.7;

  /// Computes the net g-force from 3-axis accelerometer values in m/s^2.
  ///
  /// Normalizes vector length by [gravity] (defaults to [standardGravity]).
  static double computeGForce(
    double x,
    double y,
    double z, {
    double gravity = standardGravity,
  }) {
    if (gravity <= 0) {
      throw ArgumentError.value(gravity, 'gravity', 'Gravity must be positive');
    }
    final magnitude = math.sqrt(x * x + y * y + z * z);
    return magnitude / gravity;
  }

  /// Evaluates whether the given [gForce] reaches or exceeds [threshold].
  static bool isShake(
    double gForce, {
    double threshold = defaultShakeThresholdG,
  }) {
    return gForce >= threshold;
  }
}
