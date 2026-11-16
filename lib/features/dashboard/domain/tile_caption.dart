import 'package:aquagrow_mobile/core/models/sensor_metric.dart';
import 'package:aquagrow_mobile/core/models/sensor_status.dart';

/// The line under a reading on Home.
///
/// In range it is just the target. Out of range it says which way first, so
/// the tile never relies on colour alone (DESIGN.md screen rule 8), for
/// example "Too high" above "Target 18–24°C". The direction gets its own
/// line so a narrow tile never breaks the range in two.
String tileCaption(SensorMetric metric, double value) {
  if (metric.statusOf(value) == SensorStatus.normal) return metric.targetLabel;
  final low = value < metric.targetMin;
  final direction = switch (metric) {
    SensorMetric.waterLevel => 'Running low',
    _ => low ? 'Too low' : 'Too high',
  };
  return '$direction\n${metric.targetLabel}';
}
