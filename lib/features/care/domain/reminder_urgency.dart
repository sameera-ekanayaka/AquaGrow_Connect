import 'package:aquagrow_mobile/features/care/domain/care_reminder.dart';

/// Urgency classification for a care reminder relative to current date.
///
/// Pure logic domain enum with no Flutter imports.
/// OWNER: Imasha (see docs/tasks/imasha.md).
enum ReminderUrgency {
  overdue,
  dueToday,
  upcoming,
  completed;

  /// Categorizes a reminder's urgency given reference time [now].
  static ReminderUrgency fromReminder(CareReminder reminder, DateTime now) {
    if (reminder.isCompleted) return ReminderUrgency.completed;
    final days = reminder.daysRemaining(now);
    if (days < 0) return ReminderUrgency.overdue;
    if (days == 0) return ReminderUrgency.dueToday;
    return ReminderUrgency.upcoming;
  }

  /// Formats a user-facing status label.
  String label(int daysRemaining) {
    switch (this) {
      case ReminderUrgency.completed:
        return 'Completed';
      case ReminderUrgency.overdue:
        final absDays = daysRemaining.abs();
        return absDays == 1 ? '1 day overdue' : '$absDays days overdue';
      case ReminderUrgency.dueToday:
        return 'Due today';
      case ReminderUrgency.upcoming:
        return daysRemaining == 1
            ? 'Due tomorrow'
            : 'Due in $daysRemaining days';
    }
  }
}
