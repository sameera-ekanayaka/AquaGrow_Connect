import 'package:aquagrow_mobile/core/models/crop_recipe.dart';

/// Predefined botanical recipes defining target hydroponic parameters for crops.
///
/// Includes the five seed recipes from the database schema plus
/// Genovese Basil and Baby Spinach for demo pods.
abstract final class CropRecipes {
  /// All known crop recipes in AquaGrow Connect.
  static const List<CropRecipe> all = [
    CropRecipe(
      id: 'recipe-genovese-basil',
      cropName: 'Genovese Basil',
      variety: 'Genovese',
      stageName: 'Vegetative',
      minPh: 5.8,
      maxPh: 6.4,
      targetEc: 1.6,
      targetWaterTempC: 22.0,
      lightHoursPerDay: 18,
      pumpIntervalMin: 15,
      durationDays: 28,
    ),
    CropRecipe(
      id: 'recipe-baby-spinach',
      cropName: 'Baby Spinach',
      variety: 'Savoy',
      stageName: 'Vegetative',
      minPh: 5.5,
      maxPh: 6.5,
      targetEc: 1.8,
      targetWaterTempC: 18.0,
      lightHoursPerDay: 14,
      pumpIntervalMin: 15,
      durationDays: 30,
    ),
    CropRecipe(
      id: 'recipe-butterhead-lettuce',
      cropName: 'Butterhead Lettuce',
      variety: 'Bibb',
      stageName: 'Vegetative',
      minPh: 5.6,
      maxPh: 6.2,
      targetEc: 1.4,
      targetWaterTempC: 20.0,
      lightHoursPerDay: 16,
      pumpIntervalMin: 15,
      durationDays: 30,
    ),
    CropRecipe(
      id: 'recipe-italian-basil',
      cropName: 'Italian Basil',
      variety: 'Genovese',
      stageName: 'Vegetative',
      minPh: 5.8,
      maxPh: 6.4,
      targetEc: 1.6,
      targetWaterTempC: 22.0,
      lightHoursPerDay: 18,
      pumpIntervalMin: 15,
      durationDays: 28,
    ),
    CropRecipe(
      id: 'recipe-wild-rocket',
      cropName: 'Wild Rocket',
      variety: 'Arugula',
      stageName: 'Vegetative',
      minPh: 6.0,
      maxPh: 6.8,
      targetEc: 1.5,
      targetWaterTempC: 19.5,
      lightHoursPerDay: 14,
      pumpIntervalMin: 20,
      durationDays: 25,
    ),
    CropRecipe(
      id: 'recipe-sweet-mint',
      cropName: 'Sweet Mint',
      variety: 'Spearmint',
      stageName: 'Vegetative',
      minPh: 6.0,
      maxPh: 6.5,
      targetEc: 2.0,
      targetWaterTempC: 21.0,
      lightHoursPerDay: 16,
      pumpIntervalMin: 15,
      durationDays: 35,
    ),
    CropRecipe(
      id: 'recipe-pak-choi',
      cropName: 'Pak Choi',
      variety: 'Baby Green',
      stageName: 'Vegetative',
      minPh: 6.0,
      maxPh: 7.0,
      targetEc: 1.8,
      targetWaterTempC: 20.5,
      lightHoursPerDay: 14,
      pumpIntervalMin: 15,
      durationDays: 32,
    ),
  ];

  /// Finds a recipe by crop name, or returns a fallback recipe if not found.
  static CropRecipe findForCrop(String cropName) {
    for (final recipe in all) {
      if (recipe.cropName.toLowerCase() == cropName.toLowerCase()) {
        return recipe;
      }
    }
    return CropRecipe(
      id: 'recipe-fallback',
      cropName: cropName,
      stageName: 'Vegetative',
      minPh: 5.8,
      maxPh: 6.4,
      targetEc: 1.6,
      targetWaterTempC: 20.0,
      lightHoursPerDay: 16,
      pumpIntervalMin: 15,
      durationDays: 30,
    );
  }
}
