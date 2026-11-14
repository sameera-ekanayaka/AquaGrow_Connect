import 'package:aquagrow_mobile/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.email', () {
    test('rejects empty and malformed values', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('grower'), isNotNull);
      expect(Validators.email('grower@pod'), isNotNull);
    });

    test('accepts a valid email with surrounding spaces', () {
      expect(Validators.email('  grower@aquagrow.io '), isNull);
    });
  });

  group('Validators.password', () {
    test('needs 8 characters with letters and numbers', () {
      expect(Validators.password('short1'), isNotNull);
      expect(Validators.password('longpassword'), isNotNull);
      expect(Validators.password('12345678'), isNotNull);
      expect(Validators.password('basil2026'), isNull);
    });
  });

  group('Validators.numberInRange', () {
    test('accepts values inside the pH range', () {
      expect(Validators.numberInRange('6.2', min: 0, max: 14), isNull);
    });

    test('rejects text and out-of-range values', () {
      expect(Validators.numberInRange('abc', min: 0, max: 14), isNotNull);
      expect(Validators.numberInRange('15', min: 0, max: 14), isNotNull);
    });
  });
}
