import 'package:aquagrow_mobile/features/crops/domain/harvest_passport.dart';

/// Builds a structured, tamper-evident plain text summary of [passport] for sharing.
String buildPassportShareText(HarvestPassport passport) {
  final varietyText = (passport.variety != null && passport.variety!.isNotEmpty)
      ? ' (${passport.variety})'
      : '';
  final harvestDate = passport.harvestedAt.toIso8601String().substring(0, 10);
  final waterSaved = passport.waterSavedLitres.toStringAsFixed(1);

  return '''AquaGrow Harvest Passport
Crop: ${passport.crop}$varietyText
Pod: ${passport.pod}
Harvest date: $harvestDate
Days grown: ${passport.daysGrown}
Water saved: $waterSaved L vs soil growing

Verification SHA-256:
${passport.hash}

The QR code holds this exact cryptographic hash for farm-to-table traceability.''';
}
