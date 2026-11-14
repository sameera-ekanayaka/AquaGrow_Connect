import 'dart:async';

import 'package:aquagrow_mobile/core/interfaces/i_alert_repository.dart';
import 'package:aquagrow_mobile/core/models/pod_alert.dart';

/// Keeps alerts in memory for the current session, newest first.
class InMemoryAlertRepository implements IAlertRepository {
  /// Oldest alerts are dropped beyond this many.
  static const int maxAlerts = 100;

  final List<PodAlert> _alerts = [];
  final _changes = StreamController<List<PodAlert>>.broadcast();

  @override
  Stream<List<PodAlert>> watchAlerts() async* {
    yield List.unmodifiable(_alerts);
    yield* _changes.stream;
  }

  @override
  Future<void> add(PodAlert alert) async {
    _alerts.insert(0, alert);
    if (_alerts.length > maxAlerts) _alerts.removeLast();
    _emit();
  }

  @override
  Future<void> acknowledge(String alertId) async {
    final i = _alerts.indexWhere((a) => a.id == alertId);
    if (i == -1) return;
    _alerts[i] = _alerts[i].copyWith(acknowledged: true);
    _emit();
  }

  @override
  Future<void> acknowledgeAll() async {
    for (var i = 0; i < _alerts.length; i++) {
      _alerts[i] = _alerts[i].copyWith(acknowledged: true);
    }
    _emit();
  }

  /// Closes the stream. Called by the provider when the app shuts down.
  void dispose() => _changes.close();

  void _emit() => _changes.add(List.unmodifiable(_alerts));
}
