import 'package:aquagrow_mobile/core/models/sensor_metric.dart';
import 'package:aquagrow_mobile/core/models/sensor_reading.dart';
import 'package:aquagrow_mobile/core/models/sensor_status.dart';

/// What the button on a [PriorityTask] card does.
enum PriorityAction {
  /// Confirm, then record that the reservoir was refilled.
  markRefilled,
}

/// The single most urgent problem on a pod, shown as the task card on Home.
class PriorityTask {
  /// Creates a task for [metric] at [status].
  const PriorityTask({
    required this.metric,
    required this.status,
    required this.title,
    required this.message,
    this.action,
  });

  /// The reading that is out of range.
  final SensorMetric metric;

  /// [SensorStatus.warning] or [SensorStatus.critical], never normal.
  final SensorStatus status;

  /// Short headline, for example "Water needs attention".
  final String title;

  /// What is wrong and what to do, for example "Pod Alpha is at 18%. Refill it today."
  final String message;

  /// The one-tap fix, or null when the user has to act on the pod itself.
  final PriorityAction? action;

  /// Button text for [action], for example "Mark as refilled".
  String? get actionLabel => switch (action) {
        PriorityAction.markRefilled => 'Mark as refilled',
        null => null,
      };
}

/// Order used when two readings share the same status: an empty tank harms
/// plants fastest, then pH, then temperature, then nutrients.
const priorityOrder = [
  SensorMetric.waterLevel,
  SensorMetric.ph,
  SensorMetric.waterTemp,
  SensorMetric.ec,
];

/// Picks the most urgent problem in [reading], or null when everything is
/// inside its target range.
///
/// Critical beats warning. Within one status, [priorityOrder] decides.
/// [podName] goes into the message, for example "Pod Alpha".
PriorityTask? priorityTaskFor(
  SensorReading reading, {
  required String podName,
}) {
  for (final status in const [SensorStatus.critical, SensorStatus.warning]) {
    for (final metric in priorityOrder) {
      final value = metric.valueOf(reading);
      if (metric.statusOf(value) == status) {
        return _taskFor(metric, status, value, podName);
      }
    }
  }
  return null;
}

PriorityTask _taskFor(
  SensorMetric metric,
  SensorStatus status,
  double value,
  String podName,
) {
  final critical = status == SensorStatus.critical;
  final high = value > metric.targetMax;
  final at = '$podName is at ${metric.format(value)}.';

  final (title, advice, action) = switch (metric) {
    SensorMetric.waterLevel => (
        critical ? 'Water is very low' : 'Water needs attention',
        critical ? 'Refill it now.' : 'Refill it today.',
        PriorityAction.markRefilled,
      ),
    SensorMetric.ph => high
        ? ('pH is too high', 'Give it a pH-down dose.', null)
        : ('pH is too low', 'Change part of the water.', null),
    SensorMetric.waterTemp => high
        ? ('Water is too warm', 'Move it out of direct sun.', null)
        : ('Water is too cold', 'Move it somewhere warmer.', null),
    SensorMetric.ec => high
        ? ('Nutrients are too strong', 'Top up with plain water.', null)
        : ('Nutrients are running low', 'Add nutrient solution.', null),
  };

  return PriorityTask(
    metric: metric,
    status: status,
    title: title,
    message: '$at $advice',
    action: action,
  );
}
