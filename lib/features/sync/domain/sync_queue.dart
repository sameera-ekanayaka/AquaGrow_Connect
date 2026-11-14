import 'package:aquagrow_mobile/core/models/sensor_reading.dart';

/// Readings waiting to be uploaded, oldest first.
///
/// Readings are append-only, so the queue never merges or edits them. A
/// reading whose id is already queued is ignored, and when the queue is full
/// the oldest reading is dropped to make room for the newest.
abstract interface class SyncQueue {
  /// Most readings the queue keeps (`AppConstants.maxOfflineQueueItems`).
  int get capacity;

  /// Number of readings waiting.
  int get length;

  /// Adds [reading] unless its id is already queued. Drops the oldest
  /// readings if the queue would grow past [capacity].
  Future<void> add(SensorReading reading);

  /// Up to [count] of the oldest readings, without removing them.
  List<SensorReading> peek(int count);

  /// Removes the readings with these [ids] after they were uploaded.
  Future<void> remove(Iterable<String> ids);
}

/// A [SyncQueue] kept in memory. Used in tests, and when Hive is not open.
class InMemorySyncQueue implements SyncQueue {
  /// Creates an empty queue holding at most [capacity] readings.
  InMemorySyncQueue({required this.capacity});

  @override
  final int capacity;

  // Insertion-ordered, so the first entry is always the oldest.
  final Map<String, SensorReading> _items = {};

  @override
  int get length => _items.length;

  @override
  Future<void> add(SensorReading reading) async {
    if (_items.containsKey(reading.id)) return;
    _items[reading.id] = reading;
    while (_items.length > capacity) {
      _items.remove(_items.keys.first);
    }
  }

  @override
  List<SensorReading> peek(int count) => _items.values.take(count).toList();

  @override
  Future<void> remove(Iterable<String> ids) async {
    for (final id in ids) {
      _items.remove(id);
    }
  }
}
