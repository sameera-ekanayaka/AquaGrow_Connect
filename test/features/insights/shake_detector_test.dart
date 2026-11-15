import 'dart:async';
import 'package:aquagrow_mobile/features/insights/application/shake_detector.dart';
import 'package:aquagrow_mobile/features/insights/domain/shake_detector_config.dart';
import 'package:aquagrow_mobile/features/insights/domain/shake_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  group('ShakeDetector', () {
    late StreamController<AccelerometerEvent> streamController;
    late List<DateTime> shakeTimestamps;
    late DateTime currentTime;

    setUp(() {
      streamController = StreamController<AccelerometerEvent>.broadcast();
      shakeTimestamps = [];
      currentTime = DateTime(2026, 11, 15, 10, 0, 0);
    });

    tearDown(() async {
      await streamController.close();
    });

    AccelerometerEvent makeEvent(double x, double y, double z) {
      return AccelerometerEvent(x, y, z);
    }

    test('ignores normal stationary or gentle movements below 2.7g', () async {
      final detector = ShakeDetector(
        sensorStream: streamController.stream,
        clock: () => currentTime,
        onShake: () => shakeTimestamps.add(currentTime),
      );

      detector.start();

      // Earth gravity resting flat: 1.0g
      streamController.add(makeEvent(0, 0, ShakeMath.standardGravity));
      // Gentle movement: 2.0g
      streamController.add(makeEvent(0, 0, ShakeMath.standardGravity * 2.0));
      await pumpEventQueue();

      expect(shakeTimestamps, isEmpty);
      detector.dispose();
    });

    test('triggers callback when acceleration exceeds 2.7g threshold',
        () async {
      final detector = ShakeDetector(
        sensorStream: streamController.stream,
        clock: () => currentTime,
        onShake: () => shakeTimestamps.add(currentTime),
      );

      detector.start();

      // Vigorous shake: 3.0g
      streamController.add(makeEvent(0, 0, ShakeMath.standardGravity * 3.0));
      await pumpEventQueue();

      expect(shakeTimestamps, hasLength(1));
      expect(shakeTimestamps.first, equals(currentTime));
      detector.dispose();
    });

    test('throttles shakes within the 1000ms window', () async {
      final detector = ShakeDetector(
        sensorStream: streamController.stream,
        clock: () => currentTime,
        onShake: () => shakeTimestamps.add(currentTime),
      );

      detector.start();

      // First shake at t = 0
      streamController.add(makeEvent(0, 0, ShakeMath.standardGravity * 3.0));
      await pumpEventQueue();
      expect(shakeTimestamps, hasLength(1));

      // Second shake 400ms later (within 1000ms throttle)
      currentTime = currentTime.add(const Duration(milliseconds: 400));
      streamController.add(makeEvent(0, 0, ShakeMath.standardGravity * 3.5));
      await pumpEventQueue();
      expect(shakeTimestamps, hasLength(1));

      // Third shake 800ms later (within 1000ms throttle of first shake)
      currentTime = currentTime.add(const Duration(milliseconds: 400));
      streamController.add(makeEvent(0, 0, ShakeMath.standardGravity * 4.0));
      await pumpEventQueue();
      expect(shakeTimestamps, hasLength(1));

      // Fourth shake 1100ms from the first shake (past 1000ms throttle window)
      currentTime = currentTime.add(const Duration(milliseconds: 300));
      streamController.add(makeEvent(0, 0, ShakeMath.standardGravity * 3.0));
      await pumpEventQueue();
      expect(shakeTimestamps, hasLength(2));

      detector.dispose();
    });

    test('honors custom ShakeDetectorConfig threshold and throttle', () async {
      const customConfig = ShakeDetectorConfig(
        thresholdG: 3.5,
        throttleMs: 500,
      );

      final detector = ShakeDetector(
        config: customConfig,
        sensorStream: streamController.stream,
        clock: () => currentTime,
        onShake: () => shakeTimestamps.add(currentTime),
      );

      detector.start();

      // 3.0g is below custom 3.5g threshold -> should not trigger
      streamController.add(makeEvent(0, 0, ShakeMath.standardGravity * 3.0));
      await pumpEventQueue();
      expect(shakeTimestamps, isEmpty);

      // 3.6g exceeds custom 3.5g threshold -> triggers
      streamController.add(makeEvent(0, 0, ShakeMath.standardGravity * 3.6));
      await pumpEventQueue();
      expect(shakeTimestamps, hasLength(1));

      // After 600ms (exceeding 500ms throttle) -> triggers again
      currentTime = currentTime.add(const Duration(milliseconds: 600));
      streamController.add(makeEvent(0, 0, ShakeMath.standardGravity * 3.8));
      await pumpEventQueue();
      expect(shakeTimestamps, hasLength(2));

      detector.dispose();
    });
  });
}
