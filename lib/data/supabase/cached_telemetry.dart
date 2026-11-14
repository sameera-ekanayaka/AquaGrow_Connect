import 'dart:convert';

import 'package:aquagrow_mobile/core/constants/app_constants.dart';
import 'package:aquagrow_mobile/core/models/sensor_reading.dart';
import 'package:hive/hive.dart';

/// Readings for [podId] saved in the 72-hour Hive cache by the sync service.
///
/// Returns an empty list if the cache box is not open (for example in tests)
/// and skips any entry that cannot be read.
List<SensorReading> cachedTelemetry(String podId) {
  if (!Hive.isBoxOpen(AppConstants.telemetryOfflineCacheBoxKey)) return [];
  final box = Hive.box<String>(AppConstants.telemetryOfflineCacheBoxKey);
  final readings = <SensorReading>[];
  for (final raw in box.values) {
    try {
      final reading =
          SensorReading.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      if (reading.deviceId == podId) readings.add(reading);
    } catch (_) {
      // A corrupt entry is skipped; the cache trims itself on the next write.
    }
  }
  return readings;
}
