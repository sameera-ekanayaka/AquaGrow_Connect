import 'package:aquagrow_mobile/core/models/sensor_reading.dart';
import 'package:aquagrow_mobile/data/supabase/supabase_telemetry_uploader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps a reading to a telemetry_logs row with its reading id', () {
    final row = SupabaseTelemetryUploader.toRow(
      SensorReading(
        id: 'pod-alpha-t7-1',
        deviceId: '7f1c2d4e-0000-4000-8000-000000000001',
        ph: 6.2,
        tdsPpm: 820,
        ecMs: 1.64,
        waterTempC: 21.5,
        humidityPct: 55,
        waterLevelPct: 78,
        recordedAt: DateTime.utc(2026, 11, 15, 10),
      ),
    );

    expect(row['reading_id'], 'pod-alpha-t7-1');
    expect(row['device_id'], '7f1c2d4e-0000-4000-8000-000000000001');
    expect(row['ph'], 6.2);
    expect(row['ec_ms'], 1.64);
    expect(row['water_level_pct'], 78);
    expect(row['ambient_temp_c'], isNull);
    expect(row['recorded_at'], '2026-11-15T10:00:00.000Z');
    expect(row.containsKey('id'), isFalse, reason: 'the server makes the id');
  });
}
