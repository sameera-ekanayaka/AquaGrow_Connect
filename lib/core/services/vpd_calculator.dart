import 'dart:math' as math;
import '../models/vpd_reading.dart';

/// Scientific calculation engine for Vapor Pressure Deficit (VPD),
/// leaf transpiration dynamics, and circadian photoperiod grow-light scheduling.
class VpdCalculator {
  VpdCalculator._();

  /// Calculates Saturation Vapor Pressure ($VP_{sat}$) in kiloPascals (kPa)
  /// using the Tetens psychrometric equation:
  ///
  /// \[
  /// VP_{sat}(T) = 0.61078 \times \exp\left(\frac{17.27 \times T}{T + 237.3}\right)
  /// \]
  /// where [tempC] is air temperature in degrees Celsius.
  static double calculateSaturationVaporPressure(double tempC) {
    final double exponent = (17.27 * tempC) / (tempC + 237.3);
    return 0.61078 * math.exp(exponent);
  }

  /// Calculates Actual Vapor Pressure ($VP_{act}$) in kiloPascals (kPa):
  ///
  /// \[
  /// VP_{act} = VP_{sat} \times \left(\frac{RH}{100}\right)
  /// \]
  static double calculateActualVaporPressure(double tempC, double humidityPct) {
    final double vpSat = calculateSaturationVaporPressure(tempC);
    final double clampedRh = humidityPct.clamp(0.0, 100.0);
    return vpSat * (clampedRh / 100.0);
  }

  /// Calculates comprehensive [VpdReading] including saturation, actual pressure,
  /// physiological zone categorization, and actionable hydroponic advice.
  ///
  /// [airTempC]: Ambient air temperature (°C).
  /// [humidityPct]: Relative humidity (0 - 100%).
  /// [leafTempOffsetC]: Temperature difference between leaf canopy and room air
  /// (under healthy transpiration, leaf is typically 1.0°C to 1.5°C cooler than air).
  static VpdReading calculateVpd({
    required double airTempC,
    required double humidityPct,
    double leafTempOffsetC = -1.0,
  }) {
    final double clampedRh = humidityPct.clamp(0.0, 100.0);
    final double canopyTempC = airTempC + leafTempOffsetC;

    // Saturation vapor pressure at leaf temperature
    final double leafVpSat = calculateSaturationVaporPressure(canopyTempC);

    // Actual vapor pressure in ambient room air
    final double airVpActual = calculateActualVaporPressure(airTempC, clampedRh);

    // VPD in kiloPascals
    double vpd = leafVpSat - airVpActual;
    if (vpd < 0.0) vpd = 0.0;

    final VpdZone zone = classifyVpdZone(vpd);
    final String advice = getHorticulturalAdvice(zone, airTempC, clampedRh);

    return VpdReading(
      vpdKpa: double.parse(vpd.toStringAsFixed(2)),
      saturationVpKpa: double.parse(leafVpSat.toStringAsFixed(2)),
      actualVpKpa: double.parse(airVpActual.toStringAsFixed(2)),
      airTemperatureC: airTempC,
      relativeHumidityPct: clampedRh,
      zone: zone,
      statusTitle: _getStatusTitle(zone),
      actionableAdvice: advice,
      calculatedAt: DateTime.now(),
    );
  }

  /// Classifies VPD values into physiological transpiration bands.
  static VpdZone classifyVpdZone(double vpdKpa) {
    if (vpdKpa < 0.40) {
      return VpdZone.underTranspiration;
    } else if (vpdKpa < 0.80) {
      return VpdZone.earlyVegetative;
    } else if (vpdKpa <= 1.20) {
      return VpdZone.optimalVegetative;
    } else if (vpdKpa <= 1.60) {
      return VpdZone.optimalGenerative;
    } else {
      return VpdZone.overTranspirationStress;
    }
  }

  static String _getStatusTitle(VpdZone zone) {
    switch (zone) {
      case VpdZone.underTranspiration:
        return 'Under-Transpiration (High Fungal Risk)';
      case VpdZone.earlyVegetative:
        return 'Gentle Transpiration (Seedling Zone)';
      case VpdZone.optimalVegetative:
        return 'Ideal Vegetative Transpiration';
      case VpdZone.optimalGenerative:
        return 'Ideal Generative Transpiration';
      case VpdZone.overTranspirationStress:
        return 'Stomatal Stress (Canopy Dehydration)';
    }
  }

  /// Detailed horticultural actionable advice for closed indoor soil-less systems.
  static String getHorticulturalAdvice(
    VpdZone zone,
    double tempC,
    double humidityPct,
  ) {
    switch (zone) {
      case VpdZone.underTranspiration:
        return 'Air is saturated ($humidityPct% RH). Plants cannot evaporate water to draw calcium and nitrates through roots. Increase exhaust ventilation and circulation fan speed.';
      case VpdZone.earlyVegetative:
        return 'Mild transpiration gradient. Excellent for young seedlings and root formation. Maintain current canopy airflow.';
      case VpdZone.optimalVegetative:
        return 'Perfect transpiration rate for leafy greens (Butterhead, Basil, Rocket). Stomata are fully open and nutrient absorption is optimized.';
      case VpdZone.optimalGenerative:
        return 'Robust transpiration pressure suitable for flowering or heavy vegetative foliage. Verify reservoir water level daily.';
      case VpdZone.overTranspirationStress:
        return 'Air is excessively dry or hot ($tempC°C, $humidityPct% RH). Leaves are losing water faster than roots can absorb. Dim grow-light PWM by 15% and increase ambient humidity.';
    }
  }

  /// Computes circadian photoperiod synchronization.
  /// Hydroponic leafy crops require 14 to 16 hours of cumulative light.
  /// Given local sunrise and sunset, calculates the required grow-light supplement.
  static PhotoperiodSchedule calculatePhotoperiodSchedule({
    required DateTime sunrise,
    required DateTime sunset,
    double targetTotalLightHours = 14.0,
  }) {
    final Duration daylightDuration = sunset.difference(sunrise);
    final double naturalDaylightHours = daylightDuration.inMinutes / 60.0;

    double supplementHoursNeeded = targetTotalLightHours - naturalDaylightHours;
    if (supplementHoursNeeded < 0) supplementHoursNeeded = 0;

    // Distribute supplemental lighting: split 50% before sunrise and 50% after sunset
    final int preDawnMinutes = (supplementHoursNeeded * 60 / 2).round();
    final int postDuskMinutes = (supplementHoursNeeded * 60 / 2).round();

    final DateTime growLightOnTime = sunrise.subtract(Duration(minutes: preDawnMinutes));
    final DateTime growLightOffTime = sunset.add(Duration(minutes: postDuskMinutes));

    return PhotoperiodSchedule(
      sunrise: sunrise,
      sunset: sunset,
      naturalDaylightHours: double.parse(naturalDaylightHours.toStringAsFixed(1)),
      targetLightHours: targetTotalLightHours,
      supplementalHoursNeeded: double.parse(supplementHoursNeeded.toStringAsFixed(1)),
      growLightOnTime: growLightOnTime,
      growLightOffTime: growLightOffTime,
      solarNoon: sunrise.add(Duration(minutes: (daylightDuration.inMinutes / 2).round())),
    );
  }
}

/// Photoperiod timing data structure for smart grow-light automation.
class PhotoperiodSchedule {
  final DateTime sunrise;
  final DateTime sunset;
  final DateTime solarNoon;
  final double naturalDaylightHours;
  final double targetLightHours;
  final double supplementalHoursNeeded;
  final DateTime growLightOnTime;
  final DateTime growLightOffTime;

  const PhotoperiodSchedule({
    required this.sunrise,
    required this.sunset,
    required this.solarNoon,
    required this.naturalDaylightHours,
    required this.targetLightHours,
    required this.supplementalHoursNeeded,
    required this.growLightOnTime,
    required this.growLightOffTime,
  });
}
