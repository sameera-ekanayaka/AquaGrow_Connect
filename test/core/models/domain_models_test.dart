import 'package:aquagrow_mobile/core/models/actuator_state.dart';
import 'package:aquagrow_mobile/core/models/crop_batch.dart';
import 'package:aquagrow_mobile/core/models/sensor_metric.dart';
import 'package:aquagrow_mobile/core/models/sensor_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SensorMetric', () {
    test('grades pH as normal, warning and critical', () {
      expect(SensorMetric.ph.statusOf(6.0), SensorStatus.normal);
      expect(SensorMetric.ph.statusOf(5.3), SensorStatus.warning);
      expect(SensorMetric.ph.statusOf(4.8), SensorStatus.critical);
      expect(SensorMetric.ph.statusOf(7.5), SensorStatus.critical);
    });

    test('flags low water level', () {
      expect(SensorMetric.waterLevel.statusOf(80), SensorStatus.normal);
      expect(SensorMetric.waterLevel.statusOf(25), SensorStatus.warning);
      expect(SensorMetric.waterLevel.statusOf(10), SensorStatus.critical);
    });

    test('formats values with units', () {
      expect(SensorMetric.ph.format(6.24), '6.2');
      expect(SensorMetric.waterTemp.format(21.6), '22°C');
      expect(SensorMetric.waterLevel.format(25), '25%');
      expect(SensorMetric.ph.targetLabel, 'Target 5.5–6.5');
    });
  });

  group('CropBatch', () {
    final planted = DateTime(2026, 11, 1);
    final batch = CropBatch(
      id: 'b1',
      podId: 'p1',
      cropName: 'Genovese Basil',
      plantedAt: planted,
      daysToHarvest: 28,
    );

    test('starts as a seedling', () {
      expect(batch.stage(planted.add(const Duration(days: 2))), GrowthStage.seedling);
    });

    test('moves to growing after the seedling share', () {
      final day10 = planted.add(const Duration(days: 10));
      expect(batch.stage(day10), GrowthStage.growing);
      expect(batch.dayNumber(day10), 11);
      expect(batch.daysLeft(day10), 18);
    });

    test('is ready to harvest at the end of the cycle', () {
      final day30 = planted.add(const Duration(days: 30));
      expect(batch.stage(day30), GrowthStage.readyToHarvest);
      expect(batch.daysLeft(day30), 0);
      expect(batch.progress(day30), 1.0);
    });
  });

  group('ActuatorState', () {
    test('locks dosing after too many pulses without a pH change', () {
      const state = ActuatorState.initial;
      expect(state.dosingLocked, isFalse);
      final locked = state.copyWith(
        phDosesWithoutChange: ActuatorState.maxDosesWithoutChange,
      );
      expect(locked.dosingLocked, isTrue);
    });
  });
}
