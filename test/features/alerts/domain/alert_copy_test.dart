import 'package:aquagrow_mobile/core/models/sensor_metric.dart';
import 'package:aquagrow_mobile/features/alerts/domain/alert_copy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('low pH reads as too low with the pod name and value', () {
    final copy = AlertCopy.forReading(
      metric: SensorMetric.ph,
      value: 4.8,
      podName: 'Pod Alpha',
    );
    expect(copy.title, 'pH is too low');
    expect(
      copy.message,
      'Pod Alpha reads pH 4.8. Add pH-up or change the water.',
    );
  });

  test('high pH suggests the pH-down doser', () {
    final copy = AlertCopy.forReading(
      metric: SensorMetric.ph,
      value: 7.4,
      podName: 'Pod Beta',
    );
    expect(copy.title, 'pH is too high');
    expect(copy.message, contains('pH-down'));
  });

  test('every metric has a low and a high message', () {
    for (final metric in SensorMetric.values) {
      final low = AlertCopy.forReading(
        metric: metric,
        value: metric.criticalMin - 1,
        podName: 'Pod Alpha',
      );
      final high = AlertCopy.forReading(
        metric: metric,
        value: metric.criticalMax + 1,
        podName: 'Pod Alpha',
      );
      expect(low.title, isNot(high.title), reason: metric.name);
      expect(low.message, startsWith('Pod Alpha'));
      expect(high.message, startsWith('Pod Alpha'));
    }
  });

  test('low water mentions refilling', () {
    final copy = AlertCopy.forReading(
      metric: SensorMetric.waterLevel,
      value: 12,
      podName: 'Pod Alpha',
    );
    expect(copy.title, 'Water level is low');
    expect(copy.message, 'Pod Alpha tank is at 12%. Refill the reservoir.');
  });
}
