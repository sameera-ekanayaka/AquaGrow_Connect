import 'package:aquagrow_mobile/features/insights/domain/shake_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ShakeMath', () {
    test('computeGForce calculates correct g-force for zero acceleration', () {
      final gForce = ShakeMath.computeGForce(0, 0, 0);
      expect(gForce, equals(0.0));
    });

    test('computeGForce calculates 1.0g for standard Earth gravity on Z-axis',
        () {
      final gForce = ShakeMath.computeGForce(0, 0, ShakeMath.standardGravity);
      expect(gForce, closeTo(1.0, 0.0001));
    });

    test(
        'computeGForce calculates 1.0g for standard Earth gravity on X or Y axis',
        () {
      expect(
        ShakeMath.computeGForce(ShakeMath.standardGravity, 0, 0),
        closeTo(1.0, 0.0001),
      );
      expect(
        ShakeMath.computeGForce(0, ShakeMath.standardGravity, 0),
        closeTo(1.0, 0.0001),
      );
    });

    test('computeGForce handles negative axis readings correctly', () {
      final gForce = ShakeMath.computeGForce(0, 0, -ShakeMath.standardGravity);
      expect(gForce, closeTo(1.0, 0.0001));
    });

    test('computeGForce throws ArgumentError for zero or negative gravity', () {
      expect(
        () => ShakeMath.computeGForce(0, 0, 9.8, gravity: 0),
        throwsArgumentError,
      );
      expect(
        () => ShakeMath.computeGForce(0, 0, 9.8, gravity: -1),
        throwsArgumentError,
      );
    });

    test('isShake returns true for g-force at or above threshold', () {
      expect(ShakeMath.isShake(2.7), isTrue);
      expect(ShakeMath.isShake(2.8), isTrue);
      expect(ShakeMath.isShake(4.5), isTrue);
    });

    test('isShake returns false for g-force below threshold', () {
      expect(ShakeMath.isShake(2.699), isFalse);
      expect(ShakeMath.isShake(1.0), isFalse);
      expect(ShakeMath.isShake(0.0), isFalse);
    });

    test('isShake supports custom threshold', () {
      expect(ShakeMath.isShake(3.0, threshold: 3.5), isFalse);
      expect(ShakeMath.isShake(3.5, threshold: 3.5), isTrue);
      expect(ShakeMath.isShake(3.6, threshold: 3.5), isTrue);
    });
  });
}
