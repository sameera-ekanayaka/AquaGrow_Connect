import 'dart:async';
import 'package:aquagrow_mobile/features/insights/application/shake_detector_provider.dart';
import 'package:aquagrow_mobile/features/insights/domain/shake_detector_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  group('shakeDetector providers', () {
    test(
        'default provider values return standard config, null stream, and real clock',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final config = container.read(shakeDetectorConfigProvider);
      expect(config.thresholdG, equals(2.7));
      expect(config.throttleMs, equals(1000));

      final stream = container.read(shakeDetectorStreamProvider);
      expect(stream, isNull);

      final clock = container.read(shakeDetectorClockProvider);
      final now = clock();
      expect(
        now.isBefore(DateTime.now().add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    test(
        'providers support override with custom configurations and stream double',
        () async {
      final controller = StreamController<AccelerometerEvent>.broadcast();
      addTearDown(controller.close);

      final fixedTime = DateTime(2026, 11, 15, 14, 0);

      final container = ProviderContainer(
        overrides: [
          shakeDetectorConfigProvider.overrideWithValue(
            const ShakeDetectorConfig(thresholdG: 3.0, throttleMs: 500),
          ),
          shakeDetectorStreamProvider.overrideWithValue(controller.stream),
          shakeDetectorClockProvider.overrideWithValue(() => fixedTime),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(shakeDetectorConfigProvider).thresholdG,
        equals(3.0),
      );
      expect(
        container.read(shakeDetectorStreamProvider),
        equals(controller.stream),
      );
      expect(
        container.read(shakeDetectorClockProvider)(),
        equals(fixedTime),
      );
    });
  });
}
