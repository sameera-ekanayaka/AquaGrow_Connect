import 'dart:async';

import 'package:aquagrow_mobile/core/interfaces/i_alert_repository.dart';
import 'package:aquagrow_mobile/core/interfaces/i_telemetry_repository.dart';
import 'package:aquagrow_mobile/core/logging/app_logger.dart';
import 'package:aquagrow_mobile/core/models/pod.dart';
import 'package:aquagrow_mobile/core/models/pod_alert.dart';
import 'package:aquagrow_mobile/core/models/sensor_metric.dart';
import 'package:aquagrow_mobile/core/models/sensor_reading.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/features/alerts/domain/alert_copy.dart';
import 'package:aquagrow_mobile/features/alerts/domain/alert_rules.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _log = AppLogger('alerts');

/// Watches every pod's live readings and raises alerts when one goes wrong.
///
/// It is the app's background service for alerts: [AlertRules] decides when,
/// [AlertCopy] writes the text, and the [IAlertRepository] stores the alert.
/// Time comes from each reading's `recordedAt`, so tests stay deterministic.
class AlertEngine {
  /// Creates an engine that reads from [telemetry] and writes to [alerts].
  AlertEngine({
    required ITelemetryRepository telemetry,
    required IAlertRepository alerts,
    AlertRules? rules,
  })  : _telemetry = telemetry,
        _alerts = alerts,
        _rules = rules ?? AlertRules();

  final ITelemetryRepository _telemetry;
  final IAlertRepository _alerts;
  final AlertRules _rules;

  final Map<String, Pod> _pods = {};
  final Map<String, StreamSubscription<SensorReading>> _subscriptions = {};
  int _counter = 0;

  /// Ids of the pods currently being watched.
  Iterable<String> get watchedPodIds => _subscriptions.keys;

  /// Starts watching new pods in [pods] and stops watching removed ones.
  void watchPods(List<Pod> pods) {
    final ids = {for (final pod in pods) pod.id};
    for (final id in _subscriptions.keys.toList()) {
      if (!ids.contains(id)) {
        _subscriptions.remove(id)?.cancel();
        _pods.remove(id);
      }
    }
    for (final pod in pods) {
      _pods[pod.id] = pod;
      _subscriptions.putIfAbsent(
        pod.id,
        () => _telemetry.watchReadings(pod.id).listen(
              onReading,
              onError: (Object e, StackTrace s) =>
                  _log.error('Reading stream failed for ${pod.id}', e, s),
            ),
      );
    }
  }

  /// Checks every metric in [reading] and stores any alert the rules allow.
  Future<void> onReading(SensorReading reading) async {
    final podName = _pods[reading.deviceId]?.name ?? reading.deviceId;
    for (final metric in SensorMetric.values) {
      final value = metric.valueOf(reading);
      final severity = _rules.evaluate(
        podId: reading.deviceId,
        metric: metric,
        status: metric.statusOf(value),
        now: reading.recordedAt,
      );
      if (severity == null) continue;

      final copy =
          AlertCopy.forReading(metric: metric, value: value, podName: podName);
      final alert = PodAlert(
        id: '${reading.deviceId}-${metric.name}-'
            '${reading.recordedAt.microsecondsSinceEpoch}-${_counter++}',
        podId: reading.deviceId,
        metric: metric,
        severity: severity,
        title: copy.title,
        message: copy.message,
        value: value,
        createdAt: reading.recordedAt,
      );
      _log.info('${severity.name} alert: ${copy.title} ($podName)');
      await _alerts.add(alert);
    }
  }

  /// Stops watching every pod.
  void dispose() {
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    _subscriptions.clear();
    _pods.clear();
  }
}

/// The one running [AlertEngine]. `AppShell` watches it, so it runs while the
/// app is open, and it follows `podsProvider` as pods come and go.
final alertEngineProvider = Provider<AlertEngine>((ref) {
  final engine = AlertEngine(
    telemetry: ref.watch(telemetryRepositoryProvider),
    alerts: ref.watch(alertRepositoryProvider),
  );
  ref.listen<AsyncValue<List<Pod>>>(
    podsProvider,
    (_, next) => next.whenData(engine.watchPods),
    fireImmediately: true,
  );
  ref.onDispose(engine.dispose);
  return engine;
});
