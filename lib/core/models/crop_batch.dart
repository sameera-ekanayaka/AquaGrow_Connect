import 'package:flutter/foundation.dart';

/// Growth stages shown on crop cards and the crop detail screen.
enum GrowthStage {
  seedling('Seedling'),
  growing('Growing'),
  readyToHarvest('Ready to harvest'),
  harvested('Harvested');

  const GrowthStage(this.label);

  /// Text shown on badges.
  final String label;
}

/// One planting of one crop in one pod, from sowing to harvest.
///
/// Matches the Supabase `crop_batches` table. The stage is calculated from
/// the planting date, so it moves forward on its own every day.
@immutable
class CropBatch {
  const CropBatch({
    required this.id,
    required this.podId,
    required this.cropName,
    required this.plantedAt,
    required this.daysToHarvest,
    this.variety,
    this.imageAsset,
    this.harvestedAt,
  });

  final String id;
  final String podId;

  /// For example "Genovese Basil".
  final String cropName;
  final String? variety;

  /// Bundled photo, for example `assets/images/crops/basil.png`. Null shows an icon.
  final String? imageAsset;

  final DateTime plantedAt;

  /// Total days from planting to harvest, from the crop recipe.
  final int daysToHarvest;

  /// Set once the batch is harvested.
  final DateTime? harvestedAt;

  /// Seedlings for the first 20% of the cycle.
  static const double seedlingShare = 0.2;

  /// Whole days since planting, as of [now].
  int dayNumber(DateTime now) => now.difference(plantedAt).inDays + 1;

  /// Days left until harvest, never below zero.
  int daysLeft(DateTime now) {
    final left = daysToHarvest - now.difference(plantedAt).inDays;
    return left < 0 ? 0 : left;
  }

  /// 0.0 at planting, 1.0 at harvest day.
  double progress(DateTime now) {
    final p = now.difference(plantedAt).inHours / (daysToHarvest * 24);
    return p.clamp(0.0, 1.0).toDouble();
  }

  /// Current stage, as of [now].
  GrowthStage stage(DateTime now) {
    if (harvestedAt != null) return GrowthStage.harvested;
    final p = progress(now);
    if (p >= 1.0) return GrowthStage.readyToHarvest;
    if (p < seedlingShare) return GrowthStage.seedling;
    return GrowthStage.growing;
  }

  @override
  bool operator ==(Object other) =>
      other is CropBatch &&
      other.id == id &&
      other.podId == podId &&
      other.cropName == cropName &&
      other.plantedAt == plantedAt &&
      other.daysToHarvest == daysToHarvest &&
      other.harvestedAt == harvestedAt;

  @override
  int get hashCode => Object.hash(id, podId, cropName, plantedAt, daysToHarvest, harvestedAt);
}
