import 'package:aquagrow_mobile/core/models/sensor_metric.dart';
import 'package:aquagrow_mobile/core/models/sensor_reading.dart';
import 'package:aquagrow_mobile/features/insights/domain/history_stats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  SensorReading makeReading({
    required double ph,
    required double ec,
    required double waterTemp,
    required double waterLevel,
    required DateTime time,
  }) {
    return SensorReading(
      id: 'test-${time.millisecondsSinceEpoch}',
      deviceId: 'pod-alpha',
      ph: ph,
      tdsPpm: ec * 500,
      ecMs: ec,
      waterTempC: waterTemp,
      waterLevelPct: waterLevel,
      recordedAt: time,
    );
  }

  group('HistoryStats domain logic tests', () {
    test('handles empty readings gracefully', () {
      final stats = HistoryStats.compute(const [], SensorMetric.ph);

      expect(stats.isEmpty, isTrue);
      expect(stats.sampleCount, equals(0));
      expect(stats.min, equals(0));
      expect(stats.max, equals(0));
      expect(stats.average, equals(0));
      expect(stats.stabilityPercent, equals(0));
      expect(stats.summaryLabel(SensorMetric.ph), contains('No readings'));
    });

    test(
      'computes min, max, average, and stability accurately for known pH readings',
      () {
        final base = DateTime(2026, 11, 15, 12, 0);
        // pH target range for SensorMetric.ph is 5.5 to 6.5
        // 10 readings: 8 in-range (5.8, 6.0, 6.2, 5.6, 6.4, 6.1, 5.9, 6.3), 2 out-of-range (5.0, 7.0)
        final readings = [
          makeReading(
            ph: 5.8,
            ec: 1.8,
            waterTemp: 21,
            waterLevel: 80,
            time: base.add(const Duration(hours: 1)),
          ),
          makeReading(
            ph: 6.0,
            ec: 1.8,
            waterTemp: 21,
            waterLevel: 80,
            time: base.add(const Duration(hours: 2)),
          ),
          makeReading(
            ph: 6.2,
            ec: 1.8,
            waterTemp: 21,
            waterLevel: 80,
            time: base.add(const Duration(hours: 3)),
          ),
          makeReading(
            ph: 5.6,
            ec: 1.8,
            waterTemp: 21,
            waterLevel: 80,
            time: base.add(const Duration(hours: 4)),
          ),
          makeReading(
            ph: 6.4,
            ec: 1.8,
            waterTemp: 21,
            waterLevel: 80,
            time: base.add(const Duration(hours: 5)),
          ),
          makeReading(
            ph: 6.1,
            ec: 1.8,
            waterTemp: 21,
            waterLevel: 80,
            time: base.add(const Duration(hours: 6)),
          ),
          makeReading(
            ph: 5.9,
            ec: 1.8,
            waterTemp: 21,
            waterLevel: 80,
            time: base.add(const Duration(hours: 7)),
          ),
          makeReading(
            ph: 6.3,
            ec: 1.8,
            waterTemp: 21,
            waterLevel: 80,
            time: base.add(const Duration(hours: 8)),
          ),
          makeReading(
            ph: 5.0,
            ec: 1.8,
            waterTemp: 21,
            waterLevel: 80,
            time: base.add(const Duration(hours: 9)),
          ),
          makeReading(
            ph: 7.0,
            ec: 1.8,
            waterTemp: 21,
            waterLevel: 80,
            time: base.add(const Duration(hours: 10)),
          ),
        ];

        final stats = HistoryStats.compute(readings, SensorMetric.ph);

        expect(stats.isEmpty, isFalse);
        expect(stats.sampleCount, equals(10));
        expect(stats.min, closeTo(5.0, 0.001));
        expect(stats.max, closeTo(7.0, 0.001));
        expect(stats.average, closeTo(6.03, 0.01));
        expect(stats.stabilityPercent, closeTo(80.0, 0.01));

        final label = stats.summaryLabel(SensorMetric.ph);
        expect(label, contains('Avg 6.0'));
        expect(label, contains('Min 5.0'));
        expect(label, contains('Max 7.0'));
        expect(label, contains('80% in range'));
      },
    );

    test('reaches 100% stability when all readings stay within target range', () {
      final base = DateTime(2026, 11, 15, 12, 0);
      final readings = [
        makeReading(
          ph: 6.0,
          ec: 1.8,
          waterTemp: 21,
          waterLevel: 80,
          time: base,
        ),
        makeReading(
          ph: 6.1,
          ec: 1.9,
          waterTemp: 22,
          waterLevel: 80,
          time: base.add(const Duration(hours: 1)),
        ),
      ];

      final stats = HistoryStats.compute(readings, SensorMetric.ph);
      expect(stats.stabilityPercent, equals(100.0));
      expect(stats.summaryLabel(SensorMetric.ph), contains('100% in range'));
    });

    test('evaluates different metrics accurately (EC and Water Temperature)', () {
      final base = DateTime(2026, 11, 15, 12, 0);
      final readings = [
        makeReading(
          ph: 6.0,
          ec: 1.5,
          waterTemp: 20.0,
          waterLevel: 90,
          time: base,
        ),
        makeReading(
          ph: 6.0,
          ec: 2.0,
          waterTemp: 22.0,
          waterLevel: 85,
          time: base.add(const Duration(hours: 1)),
        ),
        makeReading(
          ph: 6.0,
          ec: 3.2,
          waterTemp: 26.0,
          waterLevel: 75,
          time: base.add(const Duration(hours: 2)),
        ),
      ];

      final ecStats = HistoryStats.compute(readings, SensorMetric.ec);
      expect(ecStats.min, closeTo(1.5, 0.01));
      expect(ecStats.max, closeTo(3.2, 0.01));
      expect(ecStats.stabilityPercent, closeTo(66.67, 0.1));
      expect(ecStats.summaryLabel(SensorMetric.ec), contains('mS/cm'));

      final tempStats = HistoryStats.compute(readings, SensorMetric.waterTemp);
      expect(tempStats.min, closeTo(20.0, 0.01));
      expect(tempStats.max, closeTo(26.0, 0.01));
      expect(tempStats.stabilityPercent, closeTo(66.67, 0.1));
      expect(tempStats.summaryLabel(SensorMetric.waterTemp), contains('°C'));
    });
  });
}
