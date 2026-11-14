import 'package:aquagrow_mobile/core/logging/app_logger.dart';
import 'package:aquagrow_mobile/core/models/sensor_reading.dart';
import 'package:aquagrow_mobile/features/sync/domain/telemetry_uploader.dart';

const _log = AppLogger('sync');

/// The uploader used without Supabase (simulation mode, the demo default).
///
/// It only logs `would upload N readings` and succeeds, so the queue is
/// cleared exactly as it would be after a real upload.
class LoggingTelemetryUploader implements TelemetryUploader {
  /// Creates the logging uploader.
  const LoggingTelemetryUploader();

  @override
  Future<void> upload(List<SensorReading> readings) async {
    _log.info('would upload ${readings.length} readings');
  }
}
