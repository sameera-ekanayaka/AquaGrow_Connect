import 'package:aquagrow_mobile/features/crops/domain/harvest_passport.dart';
import 'package:flutter_test/flutter_test.dart';

HarvestPassport _make({
  String crop = 'Genovese Basil',
  String pod = 'Pod Alpha',
  DateTime? harvestedAt,
  double? avgPh = 6.1,
}) {
  return HarvestPassport(
    crop: crop,
    pod: pod,
    plantedAt: DateTime(2026, 11),
    harvestedAt: harvestedAt ?? DateTime(2026, 11, 11),
    avgPh: avgPh,
    avgEc: 1.6,
  );
}

void main() {
  test('same input gives the same hash', () {
    expect(_make().hash, _make().hash);
    expect(_make().hash.length, 64);
  });

  test('changing any field changes the hash', () {
    final base = _make().hash;
    expect(_make(crop: 'Baby Spinach').hash, isNot(base));
    expect(_make(pod: 'Pod Beta').hash, isNot(base));
    expect(_make(harvestedAt: DateTime(2026, 11, 12)).hash, isNot(base));
    expect(_make(avgPh: 5.9).hash, isNot(base));
  });

  test('water saved is 1.8 litres per day grown', () {
    final p = _make();
    expect(p.daysGrown, 10);
    expect(p.waterSavedLitres, closeTo(18.0, 0.001));
  });

  test('days grown never goes below zero', () {
    expect(_make(harvestedAt: DateTime(2026, 10, 1)).daysGrown, 0);
  });

  test('qr data contains the hash and the crop', () {
    final p = _make();
    expect(p.qrData, contains(p.hash));
    expect(p.qrData, contains('Genovese Basil'));
  });
}
