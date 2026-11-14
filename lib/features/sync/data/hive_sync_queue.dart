import 'dart:convert';

import 'package:aquagrow_mobile/core/logging/app_logger.dart';
import 'package:aquagrow_mobile/core/models/sensor_reading.dart';
import 'package:aquagrow_mobile/features/sync/domain/sync_queue.dart';
import 'package:hive/hive.dart';

const _log = AppLogger('sync');

/// A [SyncQueue] saved in the Hive `offline_sync_queue` box, so readings
/// queued while offline survive the app being closed.
///
/// Hive keeps string keys sorted, so each key starts with the reading time
/// (zero-padded microseconds): the first key is always the oldest reading.
class HiveSyncQueue implements SyncQueue {
  /// Wraps an open [box] and holds at most [capacity] readings.
  HiveSyncQueue(this._box, {required this.capacity}) {
    final broken = <dynamic>[];
    for (final key in _box.keys) {
      final reading = _decode(_box.get(key));
      if (reading == null) {
        broken.add(key);
      } else {
        _keyById[reading.id] = key as String;
      }
    }
    if (broken.isNotEmpty) {
      // Old or corrupt entries would block the queue forever; drop them.
      _log.warning('Dropping ${broken.length} unreadable queue entries');
      _box.deleteAll(broken);
    }
  }

  final Box<String> _box;
  final Map<String, String> _keyById = {};

  @override
  final int capacity;

  @override
  int get length => _keyById.length;

  /// The sortable box key for [reading].
  static String keyFor(SensorReading reading) =>
      '${reading.recordedAt.microsecondsSinceEpoch.toString().padLeft(20, '0')}'
      '|${reading.id}';

  @override
  Future<void> add(SensorReading reading) async {
    if (_keyById.containsKey(reading.id)) return;
    final key = keyFor(reading);
    await _box.put(key, jsonEncode(reading.toJson()));
    _keyById[reading.id] = key;

    final overflow = _keyById.length - capacity;
    if (overflow > 0) {
      final oldest = _box.keys.take(overflow).cast<String>().toList();
      await _box.deleteAll(oldest);
      _keyById.removeWhere((_, key) => oldest.contains(key));
    }
  }

  @override
  List<SensorReading> peek(int count) {
    final readings = <SensorReading>[];
    for (final key in _box.keys) {
      if (readings.length == count) break;
      final reading = _decode(_box.get(key));
      if (reading != null) readings.add(reading);
    }
    return readings;
  }

  @override
  Future<void> remove(Iterable<String> ids) async {
    final keys = [
      for (final id in ids)
        if (_keyById.remove(id) case final key?) key,
    ];
    await _box.deleteAll(keys);
  }

  static SensorReading? _decode(String? raw) {
    if (raw == null) return null;
    try {
      final reading =
          SensorReading.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      return reading.id.isEmpty ? null : reading;
    } catch (_) {
      return null;
    }
  }
}
