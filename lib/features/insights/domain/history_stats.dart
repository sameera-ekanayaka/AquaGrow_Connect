import 'package:aquagrow_mobile/core/models/sensor_metric.dart';
import 'package:aquagrow_mobile/core/models/sensor_reading.dart';

/// Summary statistics for a series of sensor readings over a time window.
///
/// Pure Dart domain model with zero Flutter dependencies, easily unit tested.
class HistoryStats {
  const HistoryStats({
    required this.min,
    required this.max,
    required this.average,
    required this.stabilityPercent,
    required this.sampleCount,
  });

  /// Empty stats sentinel when no readings are available.
  static const empty = HistoryStats(
    min: 0,
    max: 0,
    average: 0,
    stabilityPercent: 0,
    sampleCount: 0,
  );

  /// Lowest recorded value in the period.
  final double min;

  /// Highest recorded value in the period.
  final double max;

  /// Arithmetic mean of all values in the period.
  final double average;

  /// Percentage of readings that fall within the metric's target range (0.0 to 100.0).
  final double stabilityPercent;

  /// Total count of readings evaluated.
  final int sampleCount;

  /// Whether no readings were available to evaluate.
  bool get isEmpty => sampleCount == 0;

  /// Computes summary statistics for [metric] across [readings].
  factory HistoryStats.compute(
    List<SensorReading> readings,
    SensorMetric metric,
  ) {
    if (readings.isEmpty) return empty;

    double minVal = double.infinity;
    double maxVal = -double.infinity;
    double sum = 0.0;
    var inRangeCount = 0;

    for (final reading in readings) {
      final val = metric.valueOf(reading);
      if (val < minVal) minVal = val;
      if (val > maxVal) maxVal = val;
      sum += val;

      if (val >= metric.targetMin && val <= metric.targetMax) {
        inRangeCount++;
      }
    }

    final avg = sum / readings.length;
    final stability = (inRangeCount / readings.length) * 100.0;

    return HistoryStats(
      min: minVal,
      max: maxVal,
      average: avg,
      stabilityPercent: stability,
      sampleCount: readings.length,
    );
  }

  /// Formatted stats row label, e.g. `Avg 6.1 · Min 5.8 · Max 6.4 · 96% in range`.
  String summaryLabel(SensorMetric metric) {
    if (isEmpty) return 'No readings in this period';
    final avgStr = metric.format(average);
    final minStr = metric.format(min);
    final maxStr = metric.format(max);
    final stabStr = '${stabilityPercent.round()}% in range';
    return 'Avg $avgStr · Min $minStr · Max $maxStr · $stabStr';
  }
}
