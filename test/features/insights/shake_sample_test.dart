import 'package:aquagrow_mobile/features/insights/domain/shake_math.dart';
import 'package:aquagrow_mobile/features/insights/domain/shake_sample.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ShakeSample', () {
    test('computes gForce and shake detection correctly', () {
      final sample = ShakeSample(
        x: 0,
        y: 0,
        z: ShakeMath.standardGravity,
        timestamp: DateTime(2026, 11, 15, 10),
      );

      expect(sample.gForce, closeTo(1.0, 0.001));
      expect(sample.isShake(), isFalse);
    });

    test('detects shake when gForce exceeds 2.7g', () {
      final sample = ShakeSample(
        x: 0,
        y: 0,
        z: ShakeMath.standardGravity * 2.8,
        timestamp: DateTime(2026, 11, 15, 10),
      );

      expect(sample.gForce, closeTo(2.8, 0.001));
      expect(sample.isShake(), isTrue);
    });

    test('fromCoordinates uses supplied or current timestamp', () {
      final fixed = DateTime(2026, 11, 15, 12, 30);
      final sample = ShakeSample.fromCoordinates(1, 2, 3, fixed);
      expect(sample.timestamp, equals(fixed));
      expect(sample.x, equals(1));
      expect(sample.y, equals(2));
      expect(sample.z, equals(3));
    });

    test('supports value equality and hashCode', () {
      final time = DateTime(2026, 11, 15, 10);
      final s1 = ShakeSample(x: 1, y: 2, z: 3, timestamp: time);
      final s2 = ShakeSample(x: 1, y: 2, z: 3, timestamp: time);
      final s3 = ShakeSample(x: 1, y: 2, z: 4, timestamp: time);

      expect(s1, equals(s2));
      expect(s1.hashCode, equals(s2.hashCode));
      expect(s1, isNot(equals(s3)));
    });

    test('toString contains coordinates and calculated gForce', () {
      final sample = ShakeSample(
        x: 0,
        y: 0,
        z: 9.8,
        timestamp: DateTime(2026, 11, 15, 10),
      );
      expect(sample.toString(), contains('gForce: 1.00'));
    });
  });
}
