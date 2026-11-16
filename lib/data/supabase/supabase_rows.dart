import 'package:aquagrow_mobile/core/models/crop_batch.dart';
import 'package:aquagrow_mobile/core/models/pod.dart';
import 'package:aquagrow_mobile/core/models/sensor_reading.dart';

/// Columns the pod repository reads from `devices`, with the active crop
/// batch and its recipe embedded (PostgREST resource embedding).
const devicesSelect = 'id, device_name, room, is_online, last_seen_at, '
    'crop_batches(id, custom_crop_name, planted_date, status, '
    'crop_recipes(crop_name, variety, duration_days))';

/// Converts Supabase rows into the app's models. Pure functions, so they can
/// be unit tested without a network.
abstract final class SupabaseRows {
  /// A `devices` row (with embedded `crop_batches`) as a [Pod].
  static Pod pod(Map<String, dynamic> row) {
    final id = row['id'] as String;
    return Pod(
      id: id,
      name: (row['device_name'] as String?) ?? 'AquaGrow pod',
      room: (row['room'] as String?) ?? 'Home',
      isOnline: (row['is_online'] as bool?) ?? false,
      lastSeenAt: _time(row['last_seen_at']) ?? DateTime.now(),
      batch: _activeBatch(id, row['crop_batches']),
    );
  }

  /// A `telemetry_logs` row as a [SensorReading]. The app's own reading id
  /// (`reading_id`) is used when present, otherwise the server id.
  static SensorReading reading(Map<String, dynamic> row) {
    return SensorReading(
      id: (row['reading_id'] ?? row['id']).toString(),
      deviceId: row['device_id'] as String,
      ph: _num(row['ph']),
      tdsPpm: _num(row['tds_ppm']),
      ecMs: _num(row['ec_ms']),
      waterTempC: _num(row['water_temp_c']),
      ambientTempC: _numOrNull(row['ambient_temp_c']),
      humidityPct: _numOrNull(row['humidity_pct']),
      waterLevelPct: _num(row['water_level_pct']),
      recordedAt: _time(row['recorded_at'])?.toLocal() ?? DateTime.now(),
    );
  }

  /// The bundled photo for a crop name, or null for an icon placeholder.
  static String? cropImage(String cropName) {
    final name = cropName.toLowerCase();
    const dir = 'assets/images/crops';
    if (name.contains('italian basil')) return '$dir/basil-plants.webp';
    if (name.contains('basil')) return '$dir/basil.png';
    if (name.contains('spinach')) return '$dir/spinach.png';
    if (name.contains('lettuce')) return '$dir/butterhead-lettuce.webp';
    if (name.contains('rocket') || name.contains('arugula')) {
      return '$dir/wild-rocket.webp';
    }
    if (name.contains('mint')) return '$dir/sweet-mint.webp';
    if (name.contains('choi') || name.contains('bok')) {
      return '$dir/pak-choi.webp';
    }
    return null;
  }

  static CropBatch? _activeBatch(String podId, Object? batches) {
    if (batches is! List) return null;
    for (final raw in batches) {
      final b = raw as Map<String, dynamic>;
      if (b['status'] != 'ACTIVE') continue;
      final recipe = b['crop_recipes'] as Map<String, dynamic>?;
      final name = (b['custom_crop_name'] as String?)?.trim().isNotEmpty == true
          ? b['custom_crop_name'] as String
          : (recipe?['crop_name'] as String?) ?? 'Crop';
      return CropBatch(
        id: b['id'] as String,
        podId: podId,
        cropName: name,
        variety: recipe?['variety'] as String?,
        imageAsset: cropImage(name),
        plantedAt: _time(b['planted_date']) ?? DateTime.now(),
        daysToHarvest: (recipe?['duration_days'] as num?)?.toInt() ?? 30,
      );
    }
    return null;
  }

  static double _num(Object? v) => (v as num?)?.toDouble() ?? 0;

  static double? _numOrNull(Object? v) => (v as num?)?.toDouble();

  static DateTime? _time(Object? v) =>
      v is String ? DateTime.tryParse(v) : null;
}
