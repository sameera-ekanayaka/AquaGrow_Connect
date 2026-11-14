import 'package:aquagrow_mobile/core/errors/app_failure.dart';
import 'package:aquagrow_mobile/core/models/sensor_reading.dart';
import 'package:aquagrow_mobile/features/sync/domain/telemetry_uploader.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Uploads queued readings to the Supabase `telemetry_logs` table.
///
/// Uses an upsert on `reading_id` that ignores duplicates (migration 002),
/// so retrying a batch never creates a second row. Row Level Security only
/// accepts readings for devices the signed-in user owns.
class SupabaseTelemetryUploader implements TelemetryUploader {
  /// Creates an uploader that talks to [client].
  SupabaseTelemetryUploader(this._client);

  final SupabaseClient _client;

  /// The `telemetry_logs` row for [reading].
  static Map<String, dynamic> toRow(SensorReading reading) => {
        'reading_id': reading.id,
        'device_id': reading.deviceId,
        'ph': reading.ph,
        'tds_ppm': reading.tdsPpm,
        'ec_ms': reading.ecMs,
        'water_temp_c': reading.waterTempC,
        'ambient_temp_c': reading.ambientTempC,
        'humidity_pct': reading.humidityPct,
        'water_level_pct': reading.waterLevelPct,
        'recorded_at': reading.recordedAt.toUtc().toIso8601String(),
      };

  @override
  Future<void> upload(List<SensorReading> readings) async {
    if (readings.isEmpty) return;
    try {
      await _client.from('telemetry_logs').upsert(
            readings.map(toRow).toList(),
            onConflict: 'reading_id',
            ignoreDuplicates: true,
          );
    } on PostgrestException catch (e) {
      throw NetworkFailure('Could not upload readings. Will retry.', e);
    }
  }
}
