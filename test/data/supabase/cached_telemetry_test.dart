import 'dart:convert';
import 'dart:io';

import 'package:aquagrow_mobile/core/constants/app_constants.dart';
import 'package:aquagrow_mobile/core/models/sensor_reading.dart';
import 'package:aquagrow_mobile/data/supabase/cached_telemetry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  test('returns nothing when the cache box is not open', () {
    expect(cachedTelemetry('d1'), isEmpty);
  });

  test('returns only this pod readings and skips corrupt entries', () async {
    final dir = await Directory.systemTemp.createTemp('cache_test');
    addTearDown(() async {
      await Hive.deleteFromDisk();
      await dir.delete(recursive: true);
    });
    Hive.init(dir.path);
    final box =
        await Hive.openBox<String>(AppConstants.telemetryOfflineCacheBoxKey);

    SensorReading r(String id, String device) => SensorReading(
          id: id,
          deviceId: device,
          ph: 6,
          tdsPpm: 800,
          ecMs: 1.6,
          waterTempC: 21,
          waterLevelPct: 80,
          recordedAt: DateTime(2026, 11, 15, 10),
        );
    await box.put('a', jsonEncode(r('a', 'd1').toJson()));
    await box.put('b', jsonEncode(r('b', 'd2').toJson()));
    await box.put('c', '{broken');

    expect(cachedTelemetry('d1').map((x) => x.id), ['a']);
  });
}
