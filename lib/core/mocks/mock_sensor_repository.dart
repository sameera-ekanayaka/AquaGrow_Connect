import 'dart:async';
import 'dart:math';
import '../constants/app_constants.dart';
import '../interfaces/i_sensor_repository.dart';
import '../models/sensor_reading.dart';

/// Mock sensor repository providing simulated telemetry streams for parallel feature development.
class MockSensorRepository implements ISensorRepository {
  final _random = Random();
  final _telemetryController = StreamController<SensorReading>.broadcast();
  Timer? _simulationTimer;

  // Active baseline parameters
  double _currentPh = 6.0;
  double _currentEc = 1.8;
  double _currentWaterTemp = 21.5;
  double _currentWaterLevel = 85.0;

  MockSensorRepository({bool autoStart = true}) {
    if (autoStart) {
      startTelemetrySimulation();
    }
  }

  @override
  Stream<SensorReading> get telemetryStream => _telemetryController.stream;

  /// Starts broadcasting simulated sensor updates at a 2-second interval.
  void startTelemetrySimulation({Duration interval = const Duration(seconds: 2)}) {
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(interval, (_) {
      // Simulate minor natural drift
      _currentPh += (_random.nextDouble() - 0.5) * 0.05;
      _currentPh = double.parse(_currentPh.clamp(4.0, 9.0).toStringAsFixed(2));

      _currentEc += (_random.nextDouble() - 0.5) * 0.04;
      _currentEc = double.parse(_currentEc.clamp(0.2, 3.5).toStringAsFixed(2));

      _currentWaterTemp += (_random.nextDouble() - 0.5) * 0.1;
      _currentWaterTemp =
          double.parse(_currentWaterTemp.clamp(15.0, 32.0).toStringAsFixed(1));

      final reading = _createReading();
      _telemetryController.add(reading);
    });
  }

  /// Injects simulated failure scenarios for testing threshold alerts.
  void injectScenario({
    double? ph,
    double? ec,
    double? waterTemp,
    double? waterLevel,
  }) {
    if (ph != null) _currentPh = ph;
    if (ec != null) _currentEc = ec;
    if (waterTemp != null) _currentWaterTemp = waterTemp;
    if (waterLevel != null) _currentWaterLevel = waterLevel;

    _telemetryController.add(_createReading());
  }

  SensorReading _createReading() {
    return SensorReading(
      id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
      deviceId: AppConstants.mockDeviceId,
      ph: _currentPh,
      tdsPpm: double.parse((_currentEc * 500).toStringAsFixed(1)),
      ecMs: _currentEc,
      waterTempC: _currentWaterTemp,
      ambientTempC: 26.5,
      humidityPct: 68.0,
      waterLevelPct: _currentWaterLevel,
      recordedAt: DateTime.now(),
    );
  }

  @override
  Future<SensorReading> getLatestReading({String? deviceId}) async {
    return _createReading();
  }

  @override
  Future<List<SensorReading>> getHistoricalReadings({
    required String deviceId,
    required DateTime from,
    required DateTime to,
  }) async {
    final list = <SensorReading>[];
    var current = from;
    while (current.isBefore(to)) {
      list.add(
        SensorReading(
          id: 'hist-${current.millisecondsSinceEpoch}',
          deviceId: deviceId,
          ph: 5.8 + (_random.nextDouble() * 0.6),
          tdsPpm: 900.0 + (_random.nextDouble() * 100),
          ecMs: 1.8 + (_random.nextDouble() * 0.2),
          waterTempC: 21.0 + (_random.nextDouble() * 1.5),
          ambientTempC: 25.0 + (_random.nextDouble() * 2.0),
          humidityPct: 65.0 + (_random.nextDouble() * 5.0),
          waterLevelPct: 80.0,
          recordedAt: current,
        ),
      );
      current = current.add(const Duration(hours: 1));
    }
    return list;
  }

  @override
  Future<bool> sendActuatorCommand({
    required String deviceId,
    required String actuatorType,
    required dynamic value,
  }) async {
    // Acknowledge command reception
    return true;
  }

  void dispose() {
    _simulationTimer?.cancel();
    _telemetryController.close();
  }
}
