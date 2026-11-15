import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/features/care/domain/care_reminder.dart';
import 'package:aquagrow_mobile/features/care/domain/reminder_urgency.dart';
import 'package:flutter/material.dart';

/// Single reminder item in the Care tab maintenance list with completion toggle.
///
/// OWNER: Imasha (see docs/tasks/imasha.md).
class CareReminderItemTile extends StatelessWidget {
  /// The reminder data to display.
  final CareReminder reminder;

  /// Optional reference time for due date evaluation (defaults to DateTime.now).
  final DateTime? referenceNow;

  /// Callback invoked when the user toggles the completion state.
  final ValueChanged<bool?> onToggle;

  /// Creates a [CareReminderItemTile].
  const CareReminderItemTile({
    required this.reminder,
    required this.onToggle,
    this.referenceNow,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.ag;
    final now = referenceNow ?? DateTime.now();
    final days = reminder.daysRemaining(now);
    final urgency = ReminderUrgency.fromReminder(reminder, now);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AgSpace.s4),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AgRadius.all(AgRadius.r16),
          border: Border.all(color: colors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AgSpace.s12,
            vertical: AgSpace.s8,
          ),
          child: Row(
            children: [
              Checkbox(
                value: reminder.isCompleted,
                activeColor: colors.brand,
                checkColor: colors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                onChanged: onToggle,
              ),
              const SizedBox(width: AgSpace.s8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: reminder.isCompleted
                                ? colors.textSecondary
                                : colors.text,
                            decoration: reminder.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                    ),
                    const SizedBox(height: AgSpace.s4),
                    Text(
                      reminder.frequencyLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AgSpace.s8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AgSpace.s8,
                  vertical: AgSpace.s4,
                ),
                decoration: BoxDecoration(
                  color: urgency.backgroundColor(colors),
                  borderRadius: AgRadius.all(AgRadius.pill),
                ),
                child: Text(
                  urgency.label(days),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: urgency.foregroundColor(colors),
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Visual presentation extensions for [ReminderUrgency].
extension ReminderUrgencyPresentation on ReminderUrgency {
  /// Resolves the badge background color from theme tokens.
  Color backgroundColor(AgColors colors) {
    switch (this) {
      case ReminderUrgency.completed:
        return colors.brandSurface;
      case ReminderUrgency.overdue:
        return colors.criticalSurface;
      case ReminderUrgency.dueToday:
        return colors.warningSurface;
      case ReminderUrgency.upcoming:
        return colors.subtle;
    }
  }

  /// Resolves the badge text and icon color from theme tokens.
  Color foregroundColor(AgColors colors) {
    switch (this) {
      case ReminderUrgency.completed:
        return colors.brand;
      case ReminderUrgency.overdue:
        return colors.critical;
      case ReminderUrgency.dueToday:
        return colors.warning;
      case ReminderUrgency.upcoming:
        return colors.textSecondary;
    }
  }
}
