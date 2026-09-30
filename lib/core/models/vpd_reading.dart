/// Distinct biological transpiration zones for hydroponic cultivation.
enum VpdZone {
  /// VPD < 0.4 kPa: Extreme humidity, stagnant air, high risk of fungal rot / edema.
  underTranspiration,

  /// 0.4 - 0.8 kPa: Early vegetative / seedling / rooting cuttings.
  earlyVegetative,

  /// 0.8 - 1.2 kPa: Optimal late vegetative growth (Butterhead, Basil, Pak Choi).
  optimalVegetative,

  /// 1.2 - 1.6 kPa: Ideal generative / flowering / fruiting transpiration.
  optimalGenerative,

  /// VPD > 1.6 kPa: Air is excessively dry / hot; stomatal closure, nutrient tip-burn.
  overTranspirationStress,
}

/// Represents calculated Vapor Pressure Deficit (VPD) metrics and
/// physiological plant transpiration health indicators.
class VpdReading {
  final double vpdKpa;
  final double saturationVpKpa;
  final double actualVpKpa;
  final double airTemperatureC;
  final double relativeHumidityPct;
  final VpdZone zone;
  final String statusTitle;
  final String actionableAdvice;
  final DateTime calculatedAt;

  const VpdReading({
    required this.vpdKpa,
    required this.saturationVpKpa,
    required this.actualVpKpa,
    required this.airTemperatureC,
    required this.relativeHumidityPct,
    required this.zone,
    required this.statusTitle,
    required this.actionableAdvice,
    required this.calculatedAt,
  });

  /// Human-friendly display label for the current VPD zone.
  String get zoneLabel {
    switch (zone) {
      case VpdZone.underTranspiration:
        return 'Low Transpiration (Rot Risk)';
      case VpdZone.earlyVegetative:
        return 'Early Vegetative / Seedling';
      case VpdZone.optimalVegetative:
        return 'Ideal Vegetative';
      case VpdZone.optimalGenerative:
        return 'Ideal Generative';
      case VpdZone.overTranspirationStress:
        return 'High Transpiration Stress';
    }
  }

  /// Whether current VPD conditions are in the healthy cultivation bracket.
  bool get isOptimal =>
      zone == VpdZone.optimalVegetative ||
      zone == VpdZone.earlyVegetative ||
      zone == VpdZone.optimalGenerative;

  Map<String, dynamic> toJson() {
    return {
      'vpdKpa': vpdKpa,
      'saturationVpKpa': saturationVpKpa,
      'actualVpKpa': actualVpKpa,
      'airTemperatureC': airTemperatureC,
      'relativeHumidityPct': relativeHumidityPct,
      'zone': zone.name,
      'statusTitle': statusTitle,
      'actionableAdvice': actionableAdvice,
      'calculatedAt': calculatedAt.toIso8601String(),
    };
  }
}
