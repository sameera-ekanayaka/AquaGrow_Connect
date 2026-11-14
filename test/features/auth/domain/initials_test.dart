import 'package:aquagrow_mobile/features/auth/domain/initials.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('initialsFor', () {
    test('uses the first two letters of a single name', () {
      expect(initialsFor(fullName: 'Osanda'), 'OS');
    });

    test('uses the first letter of the first two words', () {
      expect(initialsFor(fullName: 'sameera  ekanayaka'), 'SE');
      expect(initialsFor(fullName: 'Ann Marie Lee'), 'AM');
    });

    test('handles a one-letter name', () {
      expect(initialsFor(fullName: 'j'), 'J');
    });

    test('falls back to the email when there is no name', () {
      expect(initialsFor(fullName: '  ', email: 'grower@aquagrow.io'), 'G');
      expect(initialsFor(email: 'viewer@aquagrow.io'), 'V');
    });

    test('falls back to A when nothing is known', () {
      expect(initialsFor(), 'A');
    });
  });
}
