import 'package:aquagrow_mobile/features/care/domain/care_reminder.dart';

/// Predefined standard hydroponic maintenance reminders for grower care routines.
///
/// OWNER: Imasha (see docs/tasks/imasha.md).
abstract final class CareReminderPresets {
  /// Filter maintenance reminder (weekly).
  static const cleanFilterId = 'care-filter';

  /// Nutrient top-up reminder (every 10 days).
  static const topUpNutrientsId = 'care-nutrients';

  /// Reservoir flush maintenance reminder (monthly).
  static const flushReservoirId = 'care-flush';

  /// Sensor calibration maintenance reminder (bi-weekly).
  static const calibrateSensorId = 'care-calibrate';

  /// Returns the default list of care reminders for an active hydroponic pod.
  static List<CareReminder> defaults([DateTime? referenceNow]) {
    final now = referenceNow ?? DateTime.now();

    return [
      CareReminder(
        id: cleanFilterId,
        title: 'Clean the filter',
        frequencyLabel: 'weekly',
        intervalDays: 7,
        lastCompletedAt: now.subtract(const Duration(days: 6)),
      ),
      CareReminder(
        id: topUpNutrientsId,
        title: 'Top up nutrients',
        frequencyLabel: 'every 10 days',
        intervalDays: 10,
        lastCompletedAt: now.subtract(const Duration(days: 7)),
      ),
      CareReminder(
        id: calibrateSensorId,
        title: 'Calibrate pH sensor',
        frequencyLabel: 'every 14 days',
        intervalDays: 14,
        lastCompletedAt: now.subtract(const Duration(days: 10)),
      ),
      CareReminder(
        id: flushReservoirId,
        title: 'Flush reservoir water',
        frequencyLabel: 'monthly',
        intervalDays: 30,
        lastCompletedAt: now.subtract(const Duration(days: 18)),
      ),
    ];
  }
}
