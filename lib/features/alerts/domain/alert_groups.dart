import 'package:aquagrow_mobile/core/models/pod_alert.dart';

/// One labelled group of alerts on the Alerts screen.
class AlertGroup {
  /// Creates a group called [label] holding [alerts], newest first.
  const AlertGroup({required this.label, required this.alerts});

  /// `Today` or `Earlier`.
  final String label;

  /// The alerts in this group, newest first.
  final List<PodAlert> alerts;
}

/// Splits [alerts] into `Today` and `Earlier`, newest first in each.
///
/// "Today" means the same calendar day as [now] in local time. Empty groups
/// are left out, so an empty list gives no groups. Pure logic, no Flutter.
List<AlertGroup> groupAlertsByDay(List<PodAlert> alerts, DateTime now) {
  final sorted = [...alerts]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  final startOfToday = DateTime(now.year, now.month, now.day);

  final today = <PodAlert>[];
  final earlier = <PodAlert>[];
  for (final alert in sorted) {
    (alert.createdAt.isBefore(startOfToday) ? earlier : today).add(alert);
  }

  return [
    if (today.isNotEmpty) AlertGroup(label: 'Today', alerts: today),
    if (earlier.isNotEmpty) AlertGroup(label: 'Earlier', alerts: earlier),
  ];
}
