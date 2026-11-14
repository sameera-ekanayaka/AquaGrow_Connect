import 'package:aquagrow_mobile/core/models/sensor_reading.dart';

/// Live and historical sensor readings for a pod.
///
/// Implementations:
/// - `SimTelemetryRepository` (lib/data/simulation): readings from the simulator. Done.
/// - Supabase `telemetry_logs` with a Hive offline cache: Sameera's task.
abstract interface class ITelemetryRepository {
  /// Emits the latest reading immediately, then every new reading for [podId].
  Stream<SensorReading> watchReadings(String podId);

  /// The most recent reading for [podId].
  Future<SensorReading> latestReading(String podId);

  /// Readings between [from] and [to], oldest first. Used by the charts.
  Future<List<SensorReading>> history(
    String podId, {
    required DateTime from,
    required DateTime to,
  });
}
