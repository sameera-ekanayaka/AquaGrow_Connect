import '../constants/app_constants.dart';

/// Immutable representation of high-frequency telemetry ingested from the hydroponic sensors.
class SensorReading {
  final String id;
  final String deviceId;
  final double ph;
  final double tdsPpm;
  final double ecMs;
  final double waterTempC;
  final double? ambientTempC;
  final double? humidityPct;
  final double waterLevelPct;
  final DateTime recordedAt;

  const SensorReading({
    required this.id,
    required this.deviceId,
    required this.ph,
    required this.tdsPpm,
    required this.ecMs,
    required this.waterTempC,
    this.ambientTempC,
    this.humidityPct,
    required this.waterLevelPct,
    required this.recordedAt,
  });

  /// Checks if the current pH reading lies within the safe biological window.
  bool isPhOptimal({
    double min = AppConstants.defaultMinPh,
    double max = AppConstants.defaultMaxPh,
  }) {
    return ph >= min && ph <= max;
  }

  /// Checks if the current electrical conductivity (EC) is optimal.
  bool isEcOptimal({
    double min = AppConstants.defaultMinEc,
    double max = AppConstants.defaultMaxEc,
  }) {
    return ecMs >= min && ecMs <= max;
  }

  /// Checks if the nutrient reservoir water temperature is in a healthy range.
  bool isWaterTempOptimal({
    double min = AppConstants.defaultMinWaterTempC,
    double max = AppConstants.defaultMaxWaterTempC,
  }) {
    return waterTempC >= min && waterTempC <= max;
  }

  /// Flags when the reservoir water level falls below the critical threshold.
  bool isWaterLevelLow({
    double threshold = AppConstants.defaultMinWaterLevelPct,
  }) {
    return waterLevelPct < threshold;
  }

  factory SensorReading.fromJson(Map<String, dynamic> json) {
    return SensorReading(
      id: json['id']?.toString() ?? '',
      deviceId: json['device_id'] as String? ?? AppConstants.mockDeviceId,
      ph: (json['ph'] as num).toDouble(),
      tdsPpm: (json['tds_ppm'] as num).toDouble(),
      ecMs: (json['ec_ms'] as num).toDouble(),
      waterTempC: (json['water_temp_c'] as num).toDouble(),
      ambientTempC: (json['ambient_temp_c'] as num?)?.toDouble(),
      humidityPct: (json['humidity_pct'] as num?)?.toDouble(),
      waterLevelPct: (json['water_level_pct'] as num).toDouble(),
      recordedAt: json['recorded_at'] != null
          ? DateTime.parse(json['recorded_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_id': deviceId,
      'ph': ph,
      'tds_ppm': tdsPpm,
      'ec_ms': ecMs,
      'water_temp_c': waterTempC,
      'ambient_temp_c': ambientTempC,
      'humidity_pct': humidityPct,
      'water_level_pct': waterLevelPct,
      'recorded_at': recordedAt.toIso8601String(),
    };
  }
}
