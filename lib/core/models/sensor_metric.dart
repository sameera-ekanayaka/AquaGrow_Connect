import 'package:aquagrow_mobile/core/models/sensor_reading.dart';
import 'package:aquagrow_mobile/core/models/sensor_status.dart';

/// A measured quantity on the pod, with its target range and danger limits.
///
/// The ranges are the defaults for leafy greens and herbs. Each metric knows
/// how to read itself from a [SensorReading], how to format itself, and how to
/// grade a value into a [SensorStatus]. Dashboard tiles, alerts and charts all
/// use this one source of truth.
enum SensorMetric {
  ph(
    label: 'pH',
    unit: '',
    decimals: 1,
    targetMin: 5.5,
    targetMax: 6.5,
    criticalMin: 5.0,
    criticalMax: 7.2,
  ),
  ec(
    label: 'Nutrients (EC)',
    unit: ' mS/cm',
    decimals: 1,
    targetMin: 1.2,
    targetMax: 2.4,
    criticalMin: 0.6,
    criticalMax: 3.0,
  ),
  waterTemp(
    label: 'Water temp',
    unit: '°C',
    decimals: 0,
    targetMin: 18,
    targetMax: 24,
    criticalMin: 14,
    criticalMax: 28,
  ),
  waterLevel(
    label: 'Water level',
    unit: '%',
    decimals: 0,
    targetMin: 30,
    targetMax: 100,
    criticalMin: 15,
    criticalMax: 101,
  );

  const SensorMetric({
    required this.label,
    required this.unit,
    required this.decimals,
    required this.targetMin,
    required this.targetMax,
    required this.criticalMin,
    required this.criticalMax,
  });

  /// Short name shown on tiles and charts.
  final String label;

  /// Unit suffix including any leading space, for example `°C` or ` mS/cm`.
  final String unit;

  /// Decimal places shown to the user.
  final int decimals;

  /// Healthy range. Inside it, status is [SensorStatus.normal].
  final double targetMin;
  final double targetMax;

  /// Outside these limits, status is [SensorStatus.critical] and an alert fires.
  final double criticalMin;
  final double criticalMax;

  /// Pulls this metric's value out of a reading.
  double valueOf(SensorReading reading) => switch (this) {
        SensorMetric.ph => reading.ph,
        SensorMetric.ec => reading.ecMs,
        SensorMetric.waterTemp => reading.waterTempC,
        SensorMetric.waterLevel => reading.waterLevelPct,
      };

  /// Grades a value against the target and critical limits.
  SensorStatus statusOf(double value) {
    if (value < criticalMin || value > criticalMax) return SensorStatus.critical;
    if (value < targetMin || value > targetMax) return SensorStatus.warning;
    return SensorStatus.normal;
  }

  /// Value with unit, for example `6.2`, `22°C` or `25%`.
  String format(double value) => '${value.toStringAsFixed(decimals)}$unit';

  /// Target range text for the tile caption, for example `Target 5.5–6.5`.
  String get targetLabel {
    if (this == SensorMetric.waterLevel) return 'Refill below ${targetMin.toStringAsFixed(0)}%';
    return 'Target ${targetMin.toStringAsFixed(decimals)}–'
        '${targetMax.toStringAsFixed(decimals)}$unit';
  }
}
