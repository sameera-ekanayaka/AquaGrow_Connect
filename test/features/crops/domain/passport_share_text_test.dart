import 'package:aquagrow_mobile/features/crops/domain/harvest_passport.dart';
import 'package:aquagrow_mobile/features/crops/domain/passport_share_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildPassportShareText', () {
    test('formats complete summary with crop, variety, hash, and water saved',
        () {
      final passport = HarvestPassport(
        crop: 'Genovese Basil',
        variety: 'Classic Italian',
        pod: 'Pod Alpha',
        plantedAt: DateTime(2026, 10, 1),
        harvestedAt: DateTime(2026, 10, 31),
        avgPh: 6.1,
        avgEc: 1.6,
      );

      final text = buildPassportShareText(passport);

      expect(text, contains('AquaGrow Harvest Passport'));
      expect(text, contains('Crop: Genovese Basil (Classic Italian)'));
      expect(text, contains('Pod: Pod Alpha'));
      expect(text, contains('Harvest date: 2026-10-31'));
      expect(text, contains('Days grown: 30'));
      expect(text, contains('Water saved: 54.0 L vs soil growing'));
      expect(text, contains('Verification SHA-256:'));
      expect(text, contains(passport.hash));
      expect(text, contains('QR code holds this exact cryptographic hash'));
    });

    test('omits variety parentheses when variety is null', () {
      final passport = HarvestPassport(
        crop: 'Baby Spinach',
        pod: 'Pod Beta',
        plantedAt: DateTime(2026, 10, 10),
        harvestedAt: DateTime(2026, 10, 25),
      );

      final text = buildPassportShareText(passport);

      expect(text, contains('Crop: Baby Spinach\n'));
      expect(text, isNot(contains('()')));
    });
  });
}
