import 'dart:io';

import 'package:aquagrow_mobile/data/local/local_data_eraser.dart';
import 'package:aquagrow_mobile/data/local/preferences_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('aquagrow_eraser_test');
    Hive.init(dir.path);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  test('clears the readings box, the queue box and the preferences', () async {
    final readings = await Hive.openBox<String>('readings_test');
    final queue = await Hive.openBox<String>('queue_test');
    await readings.put('r1', '{}');
    await queue.put('q1', '{}');
    final prefs = InMemoryPreferencesStore();
    await prefs.setString('theme_mode', 'dark');

    await HiveLocalDataEraser(
      preferences: prefs,
      boxNames: ['readings_test', 'queue_test'],
    ).eraseAll();

    expect(readings.isEmpty, isTrue);
    expect(queue.isEmpty, isTrue);
    expect(prefs.getString('theme_mode'), isNull);
  });

  test('skips boxes that are not open', () async {
    final prefs = InMemoryPreferencesStore();
    await prefs.setBool('asked', value: true);

    await HiveLocalDataEraser(preferences: prefs).eraseAll();

    expect(prefs.getBool('asked'), isFalse);
  });
}
