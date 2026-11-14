import 'package:aquagrow_mobile/core/models/sensor_reading.dart';
import 'package:aquagrow_mobile/features/sync/domain/sync_queue.dart';
import 'package:flutter_test/flutter_test.dart';

SensorReading reading(String id) => SensorReading(
      id: id,
      deviceId: 'pod-alpha',
      ph: 6,
      tdsPpm: 800,
      ecMs: 1.6,
      waterTempC: 21,
      waterLevelPct: 80,
      recordedAt: DateTime(2026, 11, 15, 10),
    );

void main() {
  group('InMemorySyncQueue', () {
    test('keeps readings oldest first', () async {
      final queue = InMemorySyncQueue(capacity: 10);
      await queue.add(reading('a'));
      await queue.add(reading('b'));
      await queue.add(reading('c'));

      expect(queue.peek(2).map((r) => r.id), ['a', 'b']);
      expect(queue.length, 3);
    });

    test('ignores a reading whose id is already queued', () async {
      final queue = InMemorySyncQueue(capacity: 10);
      await queue.add(reading('a'));
      await queue.add(reading('a'));

      expect(queue.length, 1);
    });

    test('never grows past its capacity and drops the oldest', () async {
      final queue = InMemorySyncQueue(capacity: 3);
      for (final id in ['a', 'b', 'c', 'd', 'e']) {
        await queue.add(reading(id));
      }

      expect(queue.length, 3);
      expect(queue.peek(3).map((r) => r.id), ['c', 'd', 'e']);
    });

    test('removes uploaded readings by id', () async {
      final queue = InMemorySyncQueue(capacity: 10);
      for (final id in ['a', 'b', 'c']) {
        await queue.add(reading(id));
      }

      await queue.remove(['a', 'c']);

      expect(queue.peek(10).map((r) => r.id), ['b']);
    });
  });
}
