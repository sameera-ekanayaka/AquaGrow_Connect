import 'dart:convert';

import 'package:crypto/crypto.dart';

/// The facts about one harvest, with a tamper-evident SHA-256 hash.
///
/// Water saved assumption: soil growing uses about 2 L per plant per day,
/// hydroponics about 0.2 L, so we count 1.8 L saved per day grown.
class HarvestPassport {
  /// Creates a passport from the batch facts.
  const HarvestPassport({
    required this.crop,
    required this.pod,
    required this.plantedAt,
    required this.harvestedAt,
    this.variety,
    this.avgPh,
    this.avgEc,
  });

  /// Litres of water saved per day grown (2.0 soil minus 0.2 hydroponic).
  static const double litresSavedPerDay = 1.8;

  /// Crop name, for example "Genovese Basil".
  final String crop;

  /// Optional variety.
  final String? variety;

  /// Pod name, for example "Pod Alpha".
  final String pod;

  /// Planting date.
  final DateTime plantedAt;

  /// Harvest date.
  final DateTime harvestedAt;

  /// Average pH while growing, if known.
  final double? avgPh;

  /// Average EC in mS/cm while growing, if known.
  final double? avgEc;

  /// Whole days from planting to harvest, never below zero.
  int get daysGrown {
    final days = harvestedAt.difference(plantedAt).inDays;
    return days < 0 ? 0 : days;
  }

  /// Estimated litres of water saved versus soil growing.
  double get waterSavedLitres => daysGrown * litresSavedPerDay;

  static String _date(DateTime d) => d.toIso8601String().substring(0, 10);

  static double? _round(double? v) =>
      v == null ? null : double.parse(v.toStringAsFixed(2));

  /// The facts in a fixed key order (so the hash is always the same).
  Map<String, Object?> toFacts() => {
        'crop': crop,
        'variety': variety,
        'pod': pod,
        'plantedAt': _date(plantedAt),
        'harvestedAt': _date(harvestedAt),
        'daysGrown': daysGrown,
        'avgPh': _round(avgPh),
        'avgEc': _round(avgEc),
        'waterSavedLitres': double.parse(waterSavedLitres.toStringAsFixed(1)),
      };

  /// SHA-256 (64 hex characters) of the facts as JSON.
  String get hash =>
      sha256.convert(utf8.encode(jsonEncode(toFacts()))).toString();

  /// First 8 characters of [hash], shown under the QR code.
  String get shortHash => hash.substring(0, 8);

  /// Text stored in the QR code: the facts plus the hash.
  String get qrData => jsonEncode({...toFacts(), 'hash': hash});
}
