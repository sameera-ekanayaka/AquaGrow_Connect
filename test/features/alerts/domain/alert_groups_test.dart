import 'package:aquagrow_mobile/core/models/pod_alert.dart';
import 'package:aquagrow_mobile/core/models/sensor_metric.dart';
import 'package:aquagrow_mobile/core/models/sensor_status.dart';
import 'package:aquagrow_mobile/features/alerts/domain/alert_groups.dart';
import 'package:flutter_test/flutter_test.dart';

PodAlert alertAt(String id, DateTime at) => PodAlert(
      id: id,
      podId: 'pod-alpha',
      metric: SensorMetric.ph,
      severity: SensorStatus.critical,
      title: 'pH is too low',
      message: 'Pod Alpha reads pH 4.8.',
      value: 4.8,
      createdAt: at,
    );

void main() {
  final now = DateTime(2026, 11, 15, 10);

  test('an empty list gives no groups', () {
    expect(groupAlertsByDay(const [], now), isEmpty);
  });

  test('splits alerts into Today and Earlier at local midnight', () {
    final groups = groupAlertsByDay(
      [
        alertAt('yesterday-late', DateTime(2026, 11, 14, 23, 59)),
        alertAt('just-after-midnight', DateTime(2026, 11, 15, 0, 1)),
        alertAt('this-morning', DateTime(2026, 11, 15, 9)),
      ],
      now,
    );

    expect(groups.map((g) => g.label), ['Today', 'Earlier']);
    expect(
      groups[0].alerts.map((a) => a.id),
      ['this-morning', 'just-after-midnight'],
    );
    expect(groups[1].alerts.map((a) => a.id), ['yesterday-late']);
  });

  test('leaves out Earlier when every alert is from today', () {
    final groups =
        groupAlertsByDay([alertAt('a', DateTime(2026, 11, 15, 8))], now);
    expect(groups.map((g) => g.label), ['Today']);
  });

  test('leaves out Today when every alert is older', () {
    final groups =
        groupAlertsByDay([alertAt('a', DateTime(2026, 11, 10))], now);
    expect(groups.map((g) => g.label), ['Earlier']);
  });
}
