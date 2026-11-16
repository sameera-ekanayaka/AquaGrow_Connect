import 'package:aquagrow_mobile/features/crops/domain/new_pod_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('name and room are required and short', () {
    expect(NewPodRules.name('Pod Gamma'), isNull);
    expect(
      NewPodRules.name('  '),
      'Pod name is required, for example Pod Gamma',
    );
    expect(NewPodRules.room(null), 'Room is required, for example Kitchen');
    expect(
      NewPodRules.room('x' * 31),
      'Keep it to 30 characters or fewer',
    );
    expect(NewPodRules.room('x' * 30), isNull);
  });

  test('serial number is 4 to 40 letters, numbers or dashes', () {
    expect(NewPodRules.serialNumber('AQG-2026-0042'), isNull);
    expect(NewPodRules.serialNumber(' aqg-01 '), isNull);
    expect(NewPodRules.serialNumber(''), 'Serial number is required');
    const format = 'Use 4 to 40 letters, numbers or dashes, as on the label';
    expect(NewPodRules.serialNumber('AQG'), format);
    expect(NewPodRules.serialNumber('AQG 2026'), format);
    expect(NewPodRules.serialNumber('A' * 41), format);
  });
}
