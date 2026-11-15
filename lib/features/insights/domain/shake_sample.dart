import 'package:aquagrow_mobile/features/insights/domain/shake_math.dart';

/// An immutable representation of a 3-axis accelerometer sample with its timestamp.
///
/// OWNER: Imasha (see docs/tasks/imasha.md).
class ShakeSample {
  /// Acceleration along the X axis in m/s^2.
  final double x;

  /// Acceleration along the Y axis in m/s^2.
  final double y;

  /// Acceleration along the Z axis in m/s^2.
  final double z;

  /// Timestamp when the sensor event occurred.
  final DateTime timestamp;

  /// Creates a sample with 3-axis acceleration and a timestamp.
  const ShakeSample({
    required this.x,
    required this.y,
    required this.z,
    required this.timestamp,
  });

  /// Factory constructor with optional timestamp defaulting to now.
  factory ShakeSample.fromCoordinates(
    double x,
    double y,
    double z, [
    DateTime? timestamp,
  ]) {
    return ShakeSample(
      x: x,
      y: y,
      z: z,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  /// The net g-force magnitude of this sample normalized by Earth gravity.
  double get gForce => ShakeMath.computeGForce(x, y, z);

  /// Evaluates whether this sample reaches or exceeds the shake threshold.
  bool isShake({double threshold = ShakeMath.defaultShakeThresholdG}) {
    return ShakeMath.isShake(gForce, threshold: threshold);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShakeSample &&
        other.x == x &&
        other.y == y &&
        other.z == z &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode => Object.hash(x, y, z, timestamp);

  @override
  String toString() {
    return 'ShakeSample(x: $x, y: $y, z: $z, gForce: ${gForce.toStringAsFixed(2)}, time: $timestamp)';
  }
}
