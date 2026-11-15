import 'package:aquagrow_mobile/core/models/sensor_metric.dart';
import 'package:aquagrow_mobile/core/models/sensor_reading.dart';
import 'package:aquagrow_mobile/core/models/sensor_status.dart';
import 'package:aquagrow_mobile/features/dashboard/domain/priority_task.dart';
import 'package:flutter_test/flutter_test.dart';

SensorReading _reading({
  double ph = 6.0,
  double ec = 1.8,
  double temp = 21,
  double level = 70,
}) =>
    SensorReading(
      id: 'r1',
      deviceId: 'pod-alpha',
      ph: ph,
      tdsPpm: 900,
      ecMs: ec,
      waterTempC: temp,
      waterLevelPct: level,
      recordedAt: DateTime(2026, 11, 15, 10),
    );

PriorityTask? _task(SensorReading r) =>
    priorityTaskFor(r, podName: 'Pod Alpha');

void main() {
  test('returns null when every reading is in range', () {
    expect(_task(_reading()), isNull);
  });

  test('low water gives the refill task with the mark-refilled action', () {
    final task = _task(_reading(level: 18))!;

    expect(task.metric, SensorMetric.waterLevel);
    expect(task.status, SensorStatus.warning);
    expect(task.title, 'Water needs attention');
    expect(task.message, 'Pod Alpha is at 18%. Refill it today.');
    expect(task.action, PriorityAction.markRefilled);
    expect(task.actionLabel, 'Mark as refilled');
  });

  test('critical beats warning even when the warning ranks higher', () {
    // Water level is only a warning, EC is critical.
    final task = _task(_reading(level: 20, ec: 3.5))!;

    expect(task.metric, SensorMetric.ec);
    expect(task.status, SensorStatus.critical);
    expect(task.title, 'Nutrients are too strong');
    expect(task.action, isNull);
  });

  test('among warnings, water level comes before pH, temp and EC', () {
    expect(
      _task(_reading(level: 20, ph: 6.8, temp: 26, ec: 1.0))!.metric,
      SensorMetric.waterLevel,
    );
    expect(
      _task(_reading(ph: 6.8, temp: 26, ec: 1.0))!.metric,
      SensorMetric.ph,
    );
    expect(_task(_reading(temp: 26, ec: 1.0))!.metric, SensorMetric.waterTemp);
    expect(_task(_reading(ec: 1.0))!.metric, SensorMetric.ec);
  });

  test('among criticals, water level comes first', () {
    final task = _task(_reading(level: 10, ph: 7.5))!;

    expect(task.metric, SensorMetric.waterLevel);
    expect(task.title, 'Water is very low');
    expect(task.message, 'Pod Alpha is at 10%. Refill it now.');
  });

  test('high and low readings get different advice', () {
    expect(_task(_reading(ph: 7.5))!.title, 'pH is too high');
    expect(_task(_reading(ph: 4.8))!.title, 'pH is too low');
    expect(_task(_reading(temp: 30))!.title, 'Water is too warm');
    expect(_task(_reading(temp: 12))!.title, 'Water is too cold');
    expect(_task(_reading(ec: 0.4))!.title, 'Nutrients are running low');
  });
}
