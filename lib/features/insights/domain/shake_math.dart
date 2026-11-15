import 'dart:math' as math;

/// Pure mathematical utilities for shake detection and g-force calculation.
///
/// OWNER: Imasha (see docs/tasks/imasha.md).
abstract final class ShakeMath {
  /// Standard gravitational acceleration constant in m/s^2.
  static const double standardGravity = 9.80665;

  /// Default g-force threshold to register a shake event.
  static const double defaultShakeThresholdG = 2.7;

  /// Computes the net acceleration vector magnitude in m/s^2.
  static double computeMagnitude(double x, double y, double z) {
    return math.sqrt(x * x + y * y + z * z);
  }

  /// Computes the Euclidean delta magnitude between two 3-axis vectors.
  static double computeDelta(
    double x1,
    double y1,
    double z1,
    double x2,
    double y2,
    double z2,
  ) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    final dz = z2 - z1;
    return math.sqrt(dx * dx + dy * dy + dz * dz);
  }

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
    return computeMagnitude(x, y, z) / gravity;
  }

  /// Evaluates whether the given [gForce] reaches or exceeds [threshold].
  static bool isShake(
    double gForce, {
    double threshold = defaultShakeThresholdG,
  }) {
    return gForce >= threshold;
  }
}
