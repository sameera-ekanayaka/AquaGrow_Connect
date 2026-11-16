import 'package:aquagrow_mobile/core/models/sensor_metric.dart';
import 'package:aquagrow_mobile/features/dashboard/domain/tile_caption.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('in range shows only the target', () {
    expect(tileCaption(SensorMetric.ph, 6.2), 'Target 5.5–6.5');
    expect(tileCaption(SensorMetric.waterLevel, 62), 'Refill below 30%');
  });

  test('above the target says too high', () {
    expect(
      tileCaption(SensorMetric.waterTemp, 25),
      'Too high · Target 18–24°C',
    );
    expect(tileCaption(SensorMetric.ph, 7.5), 'Too high · Target 5.5–6.5');
  });

  test('below the target says too low', () {
    expect(tileCaption(SensorMetric.ph, 4.8), 'Too low · Target 5.5–6.5');
    expect(
      tileCaption(SensorMetric.ec, 0.9),
      'Too low · Target 1.2–2.4 mS/cm',
    );
  });

  test('low water says running low', () {
    expect(
      tileCaption(SensorMetric.waterLevel, 12),
      'Running low · Refill below 30%',
    );
  });
}
