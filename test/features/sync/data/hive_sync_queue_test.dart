import 'dart:convert';
import 'dart:io';

import 'package:aquagrow_mobile/core/models/sensor_reading.dart';
import 'package:aquagrow_mobile/features/sync/data/hive_sync_queue.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

SensorReading reading(String id, int second) => SensorReading(
      id: id,
      deviceId: 'pod-alpha',
      ph: 6,
      tdsPpm: 800,
      ecMs: 1.6,
      waterTempC: 21,
      waterLevelPct: 80,
      recordedAt: DateTime(2026, 11, 15, 10, 0, second),
    );

void main() {
  late Directory dir;
  late Box<String> box;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('sync_queue_test');
    Hive.init(dir.path);
    box = await Hive.openBox<String>('offline_sync_queue');
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  test('returns readings oldest first, whatever order they arrived in',
      () async {
    final queue = HiveSyncQueue(box, capacity: 10);
    await queue.add(reading('late', 30));
    await queue.add(reading('early', 5));

    expect(queue.peek(2).map((r) => r.id), ['early', 'late']);
  });

  test('survives reopening the box, like an app restart', () async {
    final queue = HiveSyncQueue(box, capacity: 10);
    await queue.add(reading('a', 1));
    await queue.add(reading('b', 2));
    await box.close();

    final reopened = await Hive.openBox<String>('offline_sync_queue');
    final restored = HiveSyncQueue(reopened, capacity: 10);

    expect(restored.length, 2);
    expect(restored.peek(5).map((r) => r.id), ['a', 'b']);
  });

  test('ignores a reading id that is already queued', () async {
    final queue = HiveSyncQueue(box, capacity: 10);
    await queue.add(reading('a', 1));
    await queue.add(reading('a', 1));

    expect(queue.length, 1);
    expect(box.length, 1);
  });

  test('drops the oldest readings past its capacity', () async {
    final queue = HiveSyncQueue(box, capacity: 3);
    for (var i = 0; i < 5; i++) {
      await queue.add(reading('r$i', i));
    }

    expect(queue.length, 3);
    expect(box.length, 3);
    expect(queue.peek(3).map((r) => r.id), ['r2', 'r3', 'r4']);
  });

  test('removes uploaded readings by id', () async {
    final queue = HiveSyncQueue(box, capacity: 10);
    await queue.add(reading('a', 1));
    await queue.add(reading('b', 2));

    await queue.remove(['a']);

    expect(queue.peek(5).map((r) => r.id), ['b']);
    expect(box.length, 1);
  });

  test('drops old-format and corrupt entries when it opens', () async {
    await box.put(
      'queue_1',
      jsonEncode({'id': 'queue_1', 'type': 'telemetry_insert'}),
    );
    await box.put('broken', '{not json');

    final queue = HiveSyncQueue(box, capacity: 10);

    expect(queue.length, 0);
    expect(box.length, 0);
  });
}
