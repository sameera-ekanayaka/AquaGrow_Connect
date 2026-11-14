import 'package:aquagrow_mobile/core/models/sensor_metric.dart';

/// The human title and message for one alert.
class AlertCopy {
  /// Creates an alert text pair.
  const AlertCopy({required this.title, required this.message});

  /// Short headline, for example `pH is too low`.
  final String title;

  /// What was measured and what to do, for example
  /// `Pod Alpha reads pH 4.8. Add pH-up or change the water.`
  final String message;

  /// Writes the alert text for [metric] reading [value] on the pod [podName].
  ///
  /// The direction (too low or too high) comes from the metric's target range.
  factory AlertCopy.forReading({
    required SensorMetric metric,
    required double value,
    required String podName,
  }) {
    final low = value < metric.targetMin;
    final shown = metric.format(value);
    return switch (metric) {
      SensorMetric.ph => low
          ? AlertCopy(
              title: 'pH is too low',
              message:
                  '$podName reads pH $shown. Add pH-up or change the water.',
            )
          : AlertCopy(
              title: 'pH is too high',
              message: '$podName reads pH $shown. Run the pH-down doser.',
            ),
      SensorMetric.ec => low
          ? AlertCopy(
              title: 'Nutrients are running low',
              message: '$podName reads EC $shown. Add nutrient solution.',
            )
          : AlertCopy(
              title: 'Nutrients are too strong',
              message:
                  '$podName reads EC $shown. Top up with plain water to dilute.',
            ),
      SensorMetric.waterTemp => low
          ? AlertCopy(
              title: 'Water is too cold',
              message:
                  '$podName water is $shown. Move the pod somewhere warmer.',
            )
          : AlertCopy(
              title: 'Water is too warm',
              message:
                  '$podName water is $shown. Keep the pump on and the pod out of '
                  'direct sun.',
            ),
      SensorMetric.waterLevel => low
          ? AlertCopy(
              title: 'Water level is low',
              message: '$podName tank is at $shown. Refill the reservoir.',
            )
          : AlertCopy(
              title: 'Tank is overfull',
              message:
                  '$podName tank reads $shown. Check for overflow or leaks.',
            ),
    };
  }
}
