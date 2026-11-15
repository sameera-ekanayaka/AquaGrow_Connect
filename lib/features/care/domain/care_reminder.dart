/// Domain model representing a recurring maintenance reminder for hydroponic pod care.
///
/// OWNER: Imasha (see docs/tasks/imasha.md).
class CareReminder {
  /// Unique identifier for this reminder.
  final String id;

  /// Descriptive title of the maintenance task (e.g., "Clean the filter").
  final String title;

  /// Recurrence cadence label (e.g., "weekly", "every 10 days").
  final String frequencyLabel;

  /// Recurrence interval in days.
  final int intervalDays;

  /// Timestamp when the reminder was last completed, or null if pending initial completion.
  final DateTime? lastCompletedAt;

  /// Whether the task has been marked complete for its current cycle.
  final bool isCompleted;

  /// Creates a [CareReminder] instance.
  const CareReminder({
    required this.id,
    required this.title,
    required this.frequencyLabel,
    required this.intervalDays,
    this.lastCompletedAt,
    this.isCompleted = false,
  }) : assert(intervalDays > 0, 'intervalDays must be greater than zero');

  /// Returns a copy of this reminder with updated fields.
  CareReminder copyWith({
    String? id,
    String? title,
    String? frequencyLabel,
    int? intervalDays,
    DateTime? lastCompletedAt,
    bool? isCompleted,
  }) {
    return CareReminder(
      id: id ?? this.id,
      title: title ?? this.title,
      frequencyLabel: frequencyLabel ?? this.frequencyLabel,
      intervalDays: intervalDays ?? this.intervalDays,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CareReminder &&
        other.id == id &&
        other.title == title &&
        other.frequencyLabel == frequencyLabel &&
        other.intervalDays == intervalDays &&
        other.lastCompletedAt == lastCompletedAt &&
        other.isCompleted == isCompleted;
  }

  @override
  int get hashCode => Object.hash(
        id,
        title,
        frequencyLabel,
        intervalDays,
        lastCompletedAt,
        isCompleted,
      );

  @override
  String toString() {
    return 'CareReminder(id: $id, title: "$title", frequency: "$frequencyLabel", interval: ${intervalDays}d, completed: $isCompleted)';
  }
}
