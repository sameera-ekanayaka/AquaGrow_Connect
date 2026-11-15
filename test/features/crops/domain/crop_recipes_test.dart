import 'package:aquagrow_mobile/features/crops/domain/crop_recipes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CropRecipes', () {
    test('every recipe has min pH < max pH and positive duration days', () {
      expect(CropRecipes.all, isNotEmpty);
      for (final recipe in CropRecipes.all) {
        expect(
          recipe.minPh,
          lessThan(recipe.maxPh),
          reason: '${recipe.cropName} minPh should be less than maxPh',
        );
        expect(
          recipe.durationDays,
          greaterThan(0),
          reason: '${recipe.cropName} durationDays should be positive',
        );
        expect(
          recipe.targetEc,
          greaterThan(0.0),
          reason: '${recipe.cropName} targetEc should be positive',
        );
        expect(
          recipe.lightHoursPerDay,
          greaterThan(0),
          reason: '${recipe.cropName} light hours should be positive',
        );
      }
    });

    test('findForCrop returns matched recipe case-insensitively', () {
      final recipe = CropRecipes.findForCrop('genovese basil');
      expect(recipe.cropName, equals('Genovese Basil'));
      expect(recipe.minPh, equals(5.8));
      expect(recipe.maxPh, equals(6.4));
    });

    test('findForCrop returns default recipe for unknown crop', () {
      final recipe = CropRecipes.findForCrop('Unknown Herb');
      expect(recipe.cropName, equals('Unknown Herb'));
      expect(recipe.durationDays, greaterThan(0));
    });
  });
}
