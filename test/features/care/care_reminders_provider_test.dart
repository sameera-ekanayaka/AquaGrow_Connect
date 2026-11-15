import 'package:aquagrow_mobile/features/care/application/care_reminders_provider.dart';
import 'package:aquagrow_mobile/features/care/domain/care_reminder.dart';
import 'package:aquagrow_mobile/features/care/domain/care_reminder_presets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CareRemindersNotifier & careRemindersProvider', () {
    final fixedTime = DateTime(2026, 11, 15, 10);

    test('initializes with default care reminder presets', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final reminders = container.read(careRemindersProvider);
      expect(reminders, isNotEmpty);
      expect(
        reminders.any((r) => r.id == CareReminderPresets.cleanFilterId),
        isTrue,
      );
    });

    test(
        'toggle marks uncompleted reminder as completed and updates lastCompletedAt',
        () {
      final notifier = CareRemindersNotifier(
        initialReminders: [
          const CareReminder(
            id: 'test-1',
            title: 'Clean filter',
            frequencyLabel: 'weekly',
            intervalDays: 7,
          ),
        ],
        clock: () => fixedTime,
      );

      expect(notifier.state.first.isCompleted, isFalse);

      notifier.toggle('test-1');
      expect(notifier.state.first.isCompleted, isTrue);
      expect(notifier.state.first.lastCompletedAt, equals(fixedTime));

      // Toggle again to un-complete
      notifier.toggle('test-1');
      expect(notifier.state.first.isCompleted, isFalse);
    });

    test('markCompleted sets isCompleted to true without toggling back', () {
      final notifier = CareRemindersNotifier(
        initialReminders: [
          const CareReminder(
            id: 'test-1',
            title: 'Clean filter',
            frequencyLabel: 'weekly',
            intervalDays: 7,
          ),
        ],
        clock: () => fixedTime,
      );

      notifier.markCompleted('test-1');
      expect(notifier.state.first.isCompleted, isTrue);

      notifier.markCompleted('test-1');
      expect(notifier.state.first.isCompleted, isTrue);
    });

    test('add appends custom reminder and reset restores defaults', () {
      final notifier = CareRemindersNotifier(
        initialReminders: [],
        clock: () => fixedTime,
      );

      expect(notifier.state, isEmpty);

      const custom = CareReminder(
        id: 'custom-1',
        title: 'Prune roots',
        frequencyLabel: 'weekly',
        intervalDays: 7,
      );

      notifier.add(custom);
      expect(notifier.state, hasLength(1));
      expect(notifier.state.first.id, equals('custom-1'));

      notifier.reset();
      expect(notifier.state, hasLength(4));
    });
  });
}
