import 'package:aquagrow_mobile/core/models/sensor_reading.dart';

/// Sends a batch of readings to the cloud.
///
/// Implementations must be safe to retry: the server keeps every reading
/// (append-only) and ignores one whose id it already has. Throws if the batch
/// could not be uploaded, so the caller keeps it queued.
abstract interface class TelemetryUploader {
  /// Uploads [readings] in one request.
  Future<void> upload(List<SensorReading> readings);
}
