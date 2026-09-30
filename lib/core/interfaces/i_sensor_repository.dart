import '../models/sensor_reading.dart';

/// Abstract contract governing sensor telemetry ingestion and actuator override commands.
/// Allows parallel team development by decoupling telemetry consumers from hardware clients.
abstract class ISensorRepository {
  /// Continuous real-time stream of high-frequency sensor readings.
  Stream<SensorReading> get telemetryStream;

  /// Retrieves the latest known snapshot reading for a device.
  Future<SensorReading> getLatestReading({String? deviceId});

  /// Queries historical sensor data within a specified time interval.
  Future<List<SensorReading>> getHistoricalReadings({
    required String deviceId,
    required DateTime from,
    required DateTime to,
  });

  /// Dispatches a manual actuator override command (pumps, lights, dosers).
  Future<bool> sendActuatorCommand({
    required String deviceId,
    required String actuatorType,
    required dynamic value,
  });
}
