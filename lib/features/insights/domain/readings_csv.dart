import 'package:aquagrow_mobile/core/models/sensor_reading.dart';

/// Escapes a CSV cell value per RFC 4180 rules.
String escapeCsvCell(String value) {
  if (value.contains(',') ||
      value.contains('"') ||
      value.contains('\n') ||
      value.contains('\r')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

/// Generates a sanitized CSV export filename: `aquagrow_<slug>_<yyyyMMdd_HHmm>.csv`.
String buildCsvFileName({required String podName, required DateTime now}) {
  final slug = podName
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  final safeSlug = slug.isEmpty ? 'pod' : slug;
  final y = now.year.toString().padLeft(4, '0');
  final m = now.month.toString().padLeft(2, '0');
  final d = now.day.toString().padLeft(2, '0');
  final h = now.hour.toString().padLeft(2, '0');
  final min = now.minute.toString().padLeft(2, '0');
  return 'aquagrow_${safeSlug}_$y$m${d}_$h$min.csv';
}

/// Converts a list of [SensorReading] telemetry objects to a clean RFC 4180 CSV string.
///
/// Rows are ordered oldest first. Timestamps are formatted in ISO 8601 UTC.
String readingsToCsv(List<SensorReading> readings) {
  const header =
      'recorded_at,ph,ec_ms,tds_ppm,water_temp_c,ambient_temp_c,humidity_pct,water_level_pct';

  final buffer = StringBuffer()..writeln(header);

  if (readings.isEmpty) {
    return buffer.toString();
  }

  final sorted = List<SensorReading>.from(readings)
    ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

  for (final r in sorted) {
    final fields = [
      escapeCsvCell(r.recordedAt.toUtc().toIso8601String()),
      r.ph.toString(),
      r.ecMs.toString(),
      r.tdsPpm.toString(),
      r.waterTempC.toString(),
      r.ambientTempC != null ? r.ambientTempC.toString() : '',
      r.humidityPct != null ? r.humidityPct.toString() : '',
      r.waterLevelPct.toString(),
    ];
    buffer.writeln(fields.join(','));
  }

  return buffer.toString();
}
