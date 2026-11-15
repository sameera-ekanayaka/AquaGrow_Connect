import 'package:aquagrow_mobile/features/care/domain/care_reminder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CareReminder domain model', () {
    test('initializes with required properties and defaults', () {
      const reminder = CareReminder(
        id: 'r1',
        title: 'Clean the filter',
        frequencyLabel: 'weekly',
        intervalDays: 7,
      );

      expect(reminder.id, equals('r1'));
      expect(reminder.title, equals('Clean the filter'));
      expect(reminder.frequencyLabel, equals('weekly'));
      expect(reminder.intervalDays, equals(7));
      expect(reminder.lastCompletedAt, isNull);
      expect(reminder.isCompleted, isFalse);
    });

    test('nextDueDate calculates target date from lastCompletedAt', () {
      final completed = DateTime(2026, 11, 10, 8);
      final reminder = CareReminder(
        id: 'r1',
        title: 'Clean the filter',
        frequencyLabel: 'weekly',
        intervalDays: 7,
        lastCompletedAt: completed,
      );

      final nextDue = reminder.nextDueDate();
      expect(nextDue, equals(DateTime(2026, 11, 17)));
    });

    test('handles year boundaries and leap intervals correctly', () {
      final yearEnd = DateTime(2026, 12, 28);
      const reminder = CareReminder(
        id: 'r1',
        title: 'Year end maintenance',
        frequencyLabel: 'weekly',
        intervalDays: 7,
      );

      // Null lastCompletedAt falls back to supplied reference date
      final nextYearDue = reminder.nextDueDate(yearEnd);
      expect(nextYearDue, equals(DateTime(2026, 12, 28)));

      final completedYearEnd = reminder.copyWith(lastCompletedAt: yearEnd);
      final nextDue = completedYearEnd.nextDueDate();
      expect(nextDue, equals(DateTime(2027, 1, 4)));
    });

    test('supports quarterly and long interval cadences', () {
      final start = DateTime(2026, 1, 1);
      final quarterly = CareReminder(
        id: 'q1',
        title: 'Deep clean plumbing',
        frequencyLabel: 'quarterly',
        intervalDays: 90,
        lastCompletedAt: start,
      );

      final nextDue = quarterly.nextDueDate();
      expect(nextDue, equals(DateTime(2026, 4, 1)));
      expect(quarterly.daysRemaining(DateTime(2026, 3, 22)), equals(10));
    });

    test('daysRemaining, isDueToday, and isOverdue evaluate accurately', () {
      final completed = DateTime(2026, 11, 5);
      final reminder = CareReminder(
        id: 'r1',
        title: 'Clean the filter',
        frequencyLabel: 'weekly',
        intervalDays: 7,
        lastCompletedAt: completed,
      );
      // nextDueDate is Nov 12

      final before = DateTime(2026, 11, 10); // 2 days left
      expect(reminder.daysRemaining(before), equals(2));
      expect(reminder.isDueToday(before), isFalse);
      expect(reminder.isOverdue(before), isFalse);

      final onDay = DateTime(2026, 11, 12); // due today
      expect(reminder.daysRemaining(onDay), equals(0));
      expect(reminder.isDueToday(onDay), isTrue);
      expect(reminder.isOverdue(onDay), isFalse);

      final overdue = DateTime(2026, 11, 14); // 2 days overdue
      expect(reminder.daysRemaining(overdue), equals(-2));
      expect(reminder.isDueToday(overdue), isFalse);
      expect(reminder.isOverdue(overdue), isTrue);

      // Completed tasks are not marked overdue or due today
      final completedReminder = reminder.copyWith(isCompleted: true);
      expect(completedReminder.isOverdue(overdue), isFalse);
      expect(completedReminder.isDueToday(onDay), isFalse);
    });

    test('validates that intervalDays is positive', () {
      expect(
        () => CareReminder(
          id: 'invalid',
          title: 'Invalid',
          frequencyLabel: 'never',
          intervalDays: 0,
        ),
        throwsAssertionError,
      );
    });

    test('copyWith updates targeted fields while retaining others', () {
      final completedTime = DateTime(2026, 11, 15, 10);
      const original = CareReminder(
        id: 'r1',
        title: 'Clean the filter',
        frequencyLabel: 'weekly',
        intervalDays: 7,
      );

      final updated = original.copyWith(
        isCompleted: true,
        lastCompletedAt: completedTime,
      );

      expect(updated.id, equals('r1'));
      expect(updated.title, equals('Clean the filter'));
      expect(updated.isCompleted, isTrue);
      expect(updated.lastCompletedAt, equals(completedTime));
    });

    test('implements value equality and hashCode', () {
      const a = CareReminder(
        id: 'r1',
        title: 'Clean the filter',
        frequencyLabel: 'weekly',
        intervalDays: 7,
      );
      const b = CareReminder(
        id: 'r1',
        title: 'Clean the filter',
        frequencyLabel: 'weekly',
        intervalDays: 7,
      );
      const c = CareReminder(
        id: 'r2',
        title: 'Top up nutrients',
        frequencyLabel: 'every 10 days',
        intervalDays: 10,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('toString contains model summary', () {
      const reminder = CareReminder(
        id: 'r1',
        title: 'Clean the filter',
        frequencyLabel: 'weekly',
        intervalDays: 7,
      );

      expect(reminder.toString(), contains('Clean the filter'));
      expect(reminder.toString(), contains('weekly'));
    });
  });
}
