import 'package:aquagrow_mobile/core/theme/app_theme.dart';
import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/features/care/domain/care_reminder.dart';
import 'package:aquagrow_mobile/features/care/domain/reminder_urgency.dart';
import 'package:aquagrow_mobile/features/care/presentation/widgets/care_reminder_item_tile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReminderUrgency', () {
    final now = DateTime(2026, 11, 15);
    final colors = AppTheme.light.extension<AgColors>()!;

    test('classifies completed reminder regardless of dates', () {
      final reminder = CareReminder(
        id: 'r1',
        title: 'Clean filter',
        frequencyLabel: 'weekly',
        intervalDays: 7,
        lastCompletedAt: now.subtract(const Duration(days: 20)),
        isCompleted: true,
      );

      final urgency = ReminderUrgency.fromReminder(reminder, now);
      expect(urgency, equals(ReminderUrgency.completed));
      expect(urgency.label(0), equals('Completed'));
      expect(urgency.backgroundColor(colors), equals(colors.brandSurface));
      expect(urgency.foregroundColor(colors), equals(colors.brand));
    });

    test('classifies overdue reminder with proper day pluralization', () {
      final reminder = CareReminder(
        id: 'r1',
        title: 'Clean filter',
        frequencyLabel: 'weekly',
        intervalDays: 7,
        lastCompletedAt: now.subtract(const Duration(days: 9)),
        isCompleted: false,
      );
      // nextDueDate was 2 days ago

      final urgency = ReminderUrgency.fromReminder(reminder, now);
      expect(urgency, equals(ReminderUrgency.overdue));
      expect(urgency.label(-2), equals('2 days overdue'));
      expect(urgency.label(-1), equals('1 day overdue'));
      expect(urgency.backgroundColor(colors), equals(colors.criticalSurface));
      expect(urgency.foregroundColor(colors), equals(colors.critical));
    });

    test('classifies dueToday reminder', () {
      final reminder = CareReminder(
        id: 'r1',
        title: 'Clean filter',
        frequencyLabel: 'weekly',
        intervalDays: 7,
        lastCompletedAt: now.subtract(const Duration(days: 7)),
        isCompleted: false,
      );
      // nextDueDate is today

      final urgency = ReminderUrgency.fromReminder(reminder, now);
      expect(urgency, equals(ReminderUrgency.dueToday));
      expect(urgency.label(0), equals('Due today'));
      expect(urgency.backgroundColor(colors), equals(colors.warningSurface));
      expect(urgency.foregroundColor(colors), equals(colors.warning));
    });

    test('classifies upcoming reminder with tomorrow and plural days', () {
      final reminder = CareReminder(
        id: 'r1',
        title: 'Clean filter',
        frequencyLabel: 'weekly',
        intervalDays: 7,
        lastCompletedAt: now.subtract(const Duration(days: 4)),
        isCompleted: false,
      );

      final urgency = ReminderUrgency.fromReminder(reminder, now);
      expect(urgency, equals(ReminderUrgency.upcoming));
      expect(urgency.label(1), equals('Due tomorrow'));
      expect(urgency.label(3), equals('Due in 3 days'));
      expect(urgency.backgroundColor(colors), equals(colors.subtle));
      expect(urgency.foregroundColor(colors), equals(colors.textSecondary));
    });
  });
}
