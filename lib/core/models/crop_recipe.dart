/// Represents a biological recipe defining target hydroponic parameters for a specific plant.
class CropRecipe {
  final String id;
  final String cropName;
  final String? variety;
  final String stageName;
  final double minPh;
  final double maxPh;
  final double targetEc;
  final double targetWaterTempC;
  final int lightHoursPerDay;
  final int pumpIntervalMin;
  final int durationDays;

  const CropRecipe({
    required this.id,
    required this.cropName,
    this.variety,
    required this.stageName,
    required this.minPh,
    required this.maxPh,
    required this.targetEc,
    required this.targetWaterTempC,
    this.lightHoursPerDay = 16,
    this.pumpIntervalMin = 15,
    this.durationDays = 30,
  });

  factory CropRecipe.fromJson(Map<String, dynamic> json) {
    return CropRecipe(
      id: json['id'] as String,
      cropName: json['crop_name'] as String,
      variety: json['variety'] as String?,
      stageName: json['stage_name'] as String? ?? 'Vegetative',
      minPh: (json['min_ph'] as num).toDouble(),
      maxPh: (json['max_ph'] as num).toDouble(),
      targetEc: (json['target_ec'] as num).toDouble(),
      targetWaterTempC: (json['target_water_temp_c'] as num).toDouble(),
      lightHoursPerDay: (json['light_hours_per_day'] as num?)?.toInt() ?? 16,
      pumpIntervalMin: (json['pump_interval_min'] as num?)?.toInt() ?? 15,
      durationDays: (json['duration_days'] as num?)?.toInt() ?? 30,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'crop_name': cropName,
      'variety': variety,
      'stage_name': stageName,
      'min_ph': minPh,
      'max_ph': maxPh,
      'target_ec': targetEc,
      'target_water_temp_c': targetWaterTempC,
      'light_hours_per_day': lightHoursPerDay,
      'pump_interval_min': pumpIntervalMin,
      'duration_days': durationDays,
    };
  }
}
