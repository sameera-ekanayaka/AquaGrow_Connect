import 'package:aquagrow_mobile/core/models/pod_alert.dart';

/// Stores alerts raised by the alert engine.
///
/// Implementations:
/// - `InMemoryAlertRepository` (lib/data/simulation): keeps alerts for this
///   session. Done.
/// - Hive-backed history that survives restarts: Osanda's task.
///
/// Deciding WHEN to raise an alert is not this class's job. That is the
/// alert engine in lib/features/alerts (Osanda's task).
abstract interface class IAlertRepository {
  /// Emits all alerts, newest first, immediately and on every change.
  Stream<List<PodAlert>> watchAlerts();

  /// Saves a new alert.
  Future<void> add(PodAlert alert);

  /// Marks one alert as seen.
  Future<void> acknowledge(String alertId);

  /// Marks every alert as seen.
  Future<void> acknowledgeAll();
}
