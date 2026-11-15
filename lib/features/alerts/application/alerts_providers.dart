import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/features/alerts/domain/alert_groups.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The current time for grouping alerts. Tests override it with a fixed time.
final alertsClockProvider =
    Provider<DateTime Function()>((ref) => DateTime.now);

/// Alerts split into `Today` and `Earlier`, for the Alerts screen.
final groupedAlertsProvider = Provider<AsyncValue<List<AlertGroup>>>((ref) {
  final now = ref.watch(alertsClockProvider)();
  return ref
      .watch(alertsProvider)
      .whenData((alerts) => groupAlertsByDay(alerts, now));
});
