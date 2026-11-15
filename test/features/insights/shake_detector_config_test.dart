import 'package:aquagrow_mobile/features/insights/domain/shake_detector_config.dart';
import 'package:aquagrow_mobile/features/insights/domain/shake_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ShakeDetectorConfig', () {
    test('default constructor provides default values', () {
      const config = ShakeDetectorConfig();
      expect(config.thresholdG, equals(2.7));
      expect(config.throttleMs, equals(1000));
      expect(config.gravity, equals(ShakeMath.standardGravity));
      expect(
        config.throttleDuration,
        equals(const Duration(milliseconds: 1000)),
      );
    });

    test('supports custom constructor values', () {
      const config = ShakeDetectorConfig(
        thresholdG: 3.2,
        throttleMs: 1500,
        gravity: 9.8,
      );
      expect(config.thresholdG, equals(3.2));
      expect(config.throttleMs, equals(1500));
      expect(config.gravity, equals(9.8));
      expect(
        config.throttleDuration,
        equals(const Duration(milliseconds: 1500)),
      );
    });

    test('copyWith updates specified fields', () {
      const original = ShakeDetectorConfig();
      final updated = original.copyWith(thresholdG: 3.0, throttleMs: 800);
      expect(updated.thresholdG, equals(3.0));
      expect(updated.throttleMs, equals(800));
      expect(updated.gravity, equals(ShakeMath.standardGravity));
    });

    test('equality and hashCode compare field values correctly', () {
      const a = ShakeDetectorConfig(thresholdG: 2.7, throttleMs: 1000);
      const b = ShakeDetectorConfig(thresholdG: 2.7, throttleMs: 1000);
      const c = ShakeDetectorConfig(thresholdG: 3.0, throttleMs: 1000);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('toString contains configuration details', () {
      const config = ShakeDetectorConfig(thresholdG: 2.8, throttleMs: 500);
      expect(config.toString(), contains('thresholdG: 2.8'));
      expect(config.toString(), contains('throttleMs: 500'));
    });
  });
}
