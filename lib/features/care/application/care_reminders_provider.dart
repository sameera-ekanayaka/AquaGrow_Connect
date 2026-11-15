import 'package:aquagrow_mobile/features/care/domain/care_reminder.dart';
import 'package:aquagrow_mobile/features/care/domain/care_reminder_presets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State notifier managing user care reminders and completion toggles.
///
/// OWNER: Imasha (see docs/tasks/imasha.md).
class CareRemindersNotifier extends StateNotifier<List<CareReminder>> {
  /// Clock function for deterministic timestamping in tests.
  final DateTime Function() _clock;

  /// Creates a [CareRemindersNotifier] with initial [reminders].
  CareRemindersNotifier({
    List<CareReminder>? initialReminders,
    DateTime Function()? clock,
  })  : _clock = clock ?? DateTime.now,
        super(initialReminders ?? CareReminderPresets.defaults());

  /// Toggles the completion status of the reminder with the specified [id].
  void toggle(String id, [DateTime? completionTimestamp]) {
    final now = completionTimestamp ?? _clock();
    state = [
      for (final reminder in state)
        if (reminder.id == id)
          reminder.copyWith(
            isCompleted: !reminder.isCompleted,
            lastCompletedAt:
                !reminder.isCompleted ? now : reminder.lastCompletedAt,
          )
        else
          reminder,
    ];
  }

  /// Marks a specific reminder as completed with the given timestamp.
  void markCompleted(String id, [DateTime? completionTimestamp]) {
    final now = completionTimestamp ?? _clock();
    state = [
      for (final reminder in state)
        if (reminder.id == id)
          reminder.copyWith(
            isCompleted: true,
            lastCompletedAt: now,
          )
        else
          reminder,
    ];
  }

  /// Resets all reminders back to initial defaults.
  void reset() {
    state = CareReminderPresets.defaults(_clock());
  }

  /// Appends a new custom care reminder to the list.
  void add(CareReminder reminder) {
    state = [...state, reminder];
  }
}

/// Provides the active list of care reminders for the Care tab.
final careRemindersProvider =
    StateNotifierProvider<CareRemindersNotifier, List<CareReminder>>((ref) {
  return CareRemindersNotifier();
});
