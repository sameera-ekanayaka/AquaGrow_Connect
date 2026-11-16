import 'package:aquagrow_mobile/core/services/launcher_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('cleanPhoneNumber', () {
    test('cleans local number with spaces and dashes', () {
      expect(cleanPhoneNumber('011 234-5678'), '0112345678');
      expect(cleanPhoneNumber('077-123 4567'), '0771234567');
    });

    test('preserves leading plus for international country codes', () {
      expect(cleanPhoneNumber('+94 11 234 5678'), '+94112345678');
      expect(cleanPhoneNumber('+1 (800) 555-0199'), '+18005550199');
    });

    test('handles empty or whitespace strings', () {
      expect(cleanPhoneNumber(''), '');
      expect(cleanPhoneNumber('   '), '');
    });

    test('strips parentheses and non-numeric punctuation', () {
      expect(cleanPhoneNumber('(033) 222-3344'), '0332223344');
    });
  });
}
