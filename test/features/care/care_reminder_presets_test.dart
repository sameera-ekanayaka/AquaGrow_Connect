import 'package:aquagrow_mobile/features/care/domain/care_reminder_presets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CareReminderPresets', () {
    final fixedClock = DateTime(2026, 11, 15, 10);

    test(
        'defaults contains required weekly filter and 10-day nutrient reminders',
        () {
      final presets = CareReminderPresets.defaults(fixedClock);

      expect(presets, hasLength(4));

      final filter =
          presets.firstWhere((r) => r.id == CareReminderPresets.cleanFilterId);
      expect(filter.title, equals('Clean the filter'));
      expect(filter.frequencyLabel, equals('weekly'));
      expect(filter.intervalDays, equals(7));

      final nutrients = presets
          .firstWhere((r) => r.id == CareReminderPresets.topUpNutrientsId);
      expect(nutrients.title, equals('Top up nutrients'));
      expect(nutrients.frequencyLabel, equals('every 10 days'));
      expect(nutrients.intervalDays, equals(10));
    });

    test('defaults sets realistic next due dates relative to reference clock',
        () {
      final presets = CareReminderPresets.defaults(fixedClock);

      for (final reminder in presets) {
        expect(reminder.lastCompletedAt, isNotNull);
        expect(reminder.intervalDays, greaterThan(0));
        expect(reminder.isCompleted, isFalse);
      }
    });
  });
}
