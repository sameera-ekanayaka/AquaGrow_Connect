import 'package:aquagrow_mobile/core/models/sensor_metric.dart';
import 'package:aquagrow_mobile/core/models/sensor_reading.dart';

/// Direction of a measured sensor trend over time.
enum TrendDirection {
  /// Values are increasing over the window.
  rising,

  /// Values are decreasing over the window.
  falling,

  /// Values remain relatively flat.
  steady,
}

/// A short-term trend projection for a sensor metric.
class TrendForecast {
  /// Creates a forecast for a metric trend.
  const TrendForecast({
    required this.direction,
    required this.change,
    required this.window,
    this.timeToLeaveRange,
    required this.message,
  });

  /// Whether the metric is rising, falling or steady.
  final TrendDirection direction;

  /// Absolute magnitude of change over the window.
  final double change;

  /// Time window the change was measured across.
  final Duration window;

  /// Estimated time until the metric breaches safe target limits.
  final Duration? timeToLeaveRange;

  /// Human-readable forecast description in sentence case.
  final String message;
}

/// Computes a trend projection based on readings from the last 6 hours.
///
/// Returns `null` if data is insufficient, too noisy ($R^2 < 0.5$), the trend
/// is insignificant (<5% of target span), or the current value is already out of range.
TrendForecast? computeTrend({
  required List<SensorReading> readings,
  required SensorMetric metric,
  required DateTime now,
}) {
  final cutoff = now.subtract(const Duration(hours: 6));

  final recent = readings
      .where(
          (r) => !r.recordedAt.isBefore(cutoff) && !r.recordedAt.isAfter(now))
      .toList()
    ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

  if (recent.length < 6) return null;

  final firstTime = recent.first.recordedAt;
  final lastTime = recent.last.recordedAt;
  final totalDuration = lastTime.difference(firstTime);
  if (totalDuration < const Duration(hours: 1)) return null;

  final n = recent.length;
  final xValues = <double>[];
  final yValues = <double>[];

  for (final r in recent) {
    final hours = r.recordedAt.difference(firstTime).inMilliseconds / 3600000.0;
    xValues.add(hours);
    yValues.add(metric.valueOf(r));
  }

  var sumX = 0.0;
  var sumY = 0.0;
  for (var i = 0; i < n; i++) {
    sumX += xValues[i];
    sumY += yValues[i];
  }
  final meanX = sumX / n;
  final meanY = sumY / n;

  var sxx = 0.0;
  var syy = 0.0;
  var sxy = 0.0;
  for (var i = 0; i < n; i++) {
    final dx = xValues[i] - meanX;
    final dy = yValues[i] - meanY;
    sxx += dx * dx;
    syy += dy * dy;
    sxy += dx * dy;
  }

  if (sxx == 0.0) return null;

  final slope = sxy / sxx;
  final intercept = meanY - (slope * meanX);

  if (syy == 0.0) return null;
  final rSquared = (sxy * sxy) / (sxx * syy);
  if (rSquared < 0.5) return null;

  final windowHours = xValues.last;
  final totalChange = (slope * windowHours).abs();
  final targetSpan = metric.targetMax - metric.targetMin;
  if (targetSpan > 0 && totalChange < 0.05 * targetSpan) {
    return null;
  }

  final currentFitted = (slope * windowHours) + intercept;
  if (currentFitted < metric.targetMin || currentFitted > metric.targetMax) {
    return null;
  }

  double hoursToLeave;
  TrendDirection direction;
  String verb;

  if (slope < 0) {
    hoursToLeave = (currentFitted - metric.targetMin) / -slope;
    direction = TrendDirection.falling;
    verb = 'dropped';
  } else if (slope > 0) {
    hoursToLeave = (metric.targetMax - currentFitted) / slope;
    direction = TrendDirection.rising;
    verb = 'risen';
  } else {
    return null;
  }

  if (hoursToLeave > 12.0) return null;

  final roundedWindowHours = windowHours.round().clamp(1, 24);
  final changeString =
      '${totalChange.toStringAsFixed(metric.decimals)}${metric.unit}';

  String timeText;
  if (hoursToLeave < 1.0) {
    timeText = 'less than 1 hour';
  } else {
    final roundedHours = hoursToLeave.round();
    timeText = roundedHours == 1 ? 'about 1 hour' : 'about $roundedHours hours';
  }

  final message =
      '${metric.label} has $verb $changeString in $roundedWindowHours hours. '
      'It may leave the safe range in $timeText.';

  return TrendForecast(
    direction: direction,
    change: totalChange,
    window: totalDuration,
    timeToLeaveRange: Duration(minutes: (hoursToLeave * 60).round()),
    message: message,
  );
}
