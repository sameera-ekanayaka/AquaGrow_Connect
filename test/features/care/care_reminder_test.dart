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
