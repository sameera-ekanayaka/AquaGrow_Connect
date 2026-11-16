import 'package:aquagrow_mobile/core/models/sensor_metric.dart';
import 'package:aquagrow_mobile/core/models/sensor_reading.dart';
import 'package:aquagrow_mobile/features/insights/domain/trend_forecast.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 15, 12, 0);

  SensorReading createReading({
    required DateTime time,
    double ph = 6.0,
    double ec = 1.6,
  }) {
    return SensorReading(
      id: 'r_${time.millisecondsSinceEpoch}',
      deviceId: 'pod-alpha',
      ph: ph,
      tdsPpm: 800,
      ecMs: ec,
      waterTempC: 22,
      waterLevelPct: 85,
      recordedAt: time,
    );
  }

  group('computeTrend', () {
    test('falling pH heading towards limit yields warning with estimated hours',
        () {
      // 7 points spanning 6 hours, dropping 0.05/hr from 5.95 to 5.65.
      // Current at 12:00 is 5.65. Target min is 5.5.
      // (5.65 - 5.5) / 0.05 = 3 hours until breach.
      final readings = [
        createReading(time: now.subtract(const Duration(hours: 6)), ph: 5.95),
        createReading(time: now.subtract(const Duration(hours: 5)), ph: 5.90),
        createReading(time: now.subtract(const Duration(hours: 4)), ph: 5.85),
        createReading(time: now.subtract(const Duration(hours: 3)), ph: 5.80),
        createReading(time: now.subtract(const Duration(hours: 2)), ph: 5.75),
        createReading(time: now.subtract(const Duration(hours: 1)), ph: 5.70),
        createReading(time: now, ph: 5.65),
      ];

      final forecast = computeTrend(
        readings: readings,
        metric: SensorMetric.ph,
        now: now,
      );

      expect(forecast, isNotNull);
      expect(forecast!.direction, TrendDirection.falling);
      expect(forecast.timeToLeaveRange?.inHours, 3);
      expect(
        forecast.message,
        'pH has dropped 0.3 in 6 hours. It may leave the safe range in about 3 hours.',
      );
    });

    test('flat readings return null', () {
      final readings = List.generate(
        7,
        (i) => createReading(
          time: now.subtract(Duration(hours: 6 - i)),
          ph: 6.0,
        ),
      );

      final forecast = computeTrend(
        readings: readings,
        metric: SensorMetric.ph,
        now: now,
      );

      expect(forecast, isNull);
    });

    test('noisy readings with low R-squared return null', () {
      final values = [5.6, 6.4, 5.7, 6.3, 5.6, 6.4, 5.7];
      final readings = List.generate(
        values.length,
        (i) => createReading(
          time: now.subtract(Duration(hours: 6 - i)),
          ph: values[i],
        ),
      );

      final forecast = computeTrend(
        readings: readings,
        metric: SensorMetric.ph,
        now: now,
      );

      expect(forecast, isNull);
    });

    test('fewer than 6 points return null', () {
      final readings = [
        createReading(time: now.subtract(const Duration(hours: 3)), ph: 5.9),
        createReading(time: now.subtract(const Duration(hours: 2)), ph: 5.8),
        createReading(time: now.subtract(const Duration(hours: 1)), ph: 5.7),
        createReading(time: now, ph: 5.6),
      ];

      final forecast = computeTrend(
        readings: readings,
        metric: SensorMetric.ph,
        now: now,
      );

      expect(forecast, isNull);
    });

    test('readings already outside safe range return null', () {
      final readings = List.generate(
        7,
        (i) => createReading(
          time: now.subtract(Duration(hours: 6 - i)),
          ph: 5.2 - (i * 0.05), // already below 5.5
        ),
      );

      final forecast = computeTrend(
        readings: readings,
        metric: SensorMetric.ph,
        now: now,
      );

      expect(forecast, isNull);
    });

    test('rising EC generates warning with "risen" text', () {
      // EC target 1.2 to 2.4. Rising from 1.8 to 2.1 in 6 hours (0.05/hr).
      // (2.4 - 2.1) / 0.05 = 6 hours until breach.
      final readings = [
        createReading(time: now.subtract(const Duration(hours: 6)), ec: 1.8),
        createReading(time: now.subtract(const Duration(hours: 5)), ec: 1.85),
        createReading(time: now.subtract(const Duration(hours: 4)), ec: 1.9),
        createReading(time: now.subtract(const Duration(hours: 3)), ec: 1.95),
        createReading(time: now.subtract(const Duration(hours: 2)), ec: 2.0),
        createReading(time: now.subtract(const Duration(hours: 1)), ec: 2.05),
        createReading(time: now, ec: 2.1),
      ];

      final forecast = computeTrend(
        readings: readings,
        metric: SensorMetric.ec,
        now: now,
      );

      expect(forecast, isNotNull);
      expect(forecast!.direction, TrendDirection.rising);
      expect(forecast.message, contains('risen'));
      expect(forecast.message, contains('Nutrients (EC)'));
      expect(forecast.message, contains('6 hours'));
    });
  });
}
