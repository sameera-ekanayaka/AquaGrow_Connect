import 'package:aquagrow_mobile/core/models/sensor_metric.dart';
import 'package:aquagrow_mobile/core/models/sensor_status.dart';

/// Decides WHEN an alert should be raised. Pure logic, no Flutter.
///
/// Two rules:
/// 1. **Edge-triggered.** An alert is raised only when a metric gets worse:
///    normal to warning, normal to critical, or warning to critical. Staying
///    in the same state, or getting better, raises nothing.
/// 2. **Cooldown.** At most one alert per pod + metric + severity every
///    [cooldown], so a reading that flickers across a limit does not spam
///    the user.
///
/// The time is passed in by the caller, so tests control the clock.
class AlertRules {
  /// Creates the rules with an optional [cooldown] (5 minutes by default).
  AlertRules({this.cooldown = const Duration(minutes: 5)});

  /// Minimum time between two alerts with the same pod, metric and severity.
  final Duration cooldown;

  final Map<String, SensorStatus> _lastStatus = {};
  final Map<String, DateTime> _lastRaisedAt = {};

  /// Records the new [status] of [metric] on [podId] at time [now].
  ///
  /// Returns the severity to raise an alert with, or null for no alert.
  /// The first status seen for a pod and metric is compared with normal, so
  /// a pod that is already critical when the app opens still raises an alert.
  SensorStatus? evaluate({
    required String podId,
    required SensorMetric metric,
    required SensorStatus status,
    required DateTime now,
  }) {
    final key = '$podId|${metric.name}';
    final previous = _lastStatus[key] ?? SensorStatus.normal;
    _lastStatus[key] = status;

    if (status == SensorStatus.normal) return null;
    if (status.index <= previous.index) return null;

    final cooldownKey = '$key|${status.name}';
    final lastRaised = _lastRaisedAt[cooldownKey];
    if (lastRaised != null && now.difference(lastRaised) < cooldown) {
      return null;
    }

    _lastRaisedAt[cooldownKey] = now;
    return status;
  }

  /// Forgets everything, as if the app had just started.
  void reset() {
    _lastStatus.clear();
    _lastRaisedAt.clear();
  }
}
