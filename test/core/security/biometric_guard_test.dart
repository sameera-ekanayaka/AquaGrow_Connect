import 'package:aquagrow_mobile/core/security/biometric_guard.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

/// A fake authenticator with a scripted result.
class FakeAuthenticator implements BiometricAuthenticator {
  FakeAuthenticator({
    this.available = true,
    this.passes = true,
    this.error,
  });

  final bool available;
  final bool passes;
  final Object? error;
  final reasons = <String>[];

  @override
  Future<bool> isAvailable() async {
    if (error != null) throw error!;
    return available;
  }

  @override
  Future<bool> authenticate(String reason) async {
    reasons.add(reason);
    return passes;
  }
}

void main() {
  group('BiometricGuard.confirm', () {
    test('passes when the user passes the check', () async {
      final auth = FakeAuthenticator();
      final ok = await BiometricGuard(auth).confirm('Turn the pump off');

      expect(ok, isTrue);
      expect(auth.reasons, ['Turn the pump off']);
    });

    test('refuses when the user cancels or fails', () async {
      final guard = BiometricGuard(FakeAuthenticator(passes: false));

      expect(await guard.confirm('Dose pH down'), isFalse);
    });

    test('allows without a prompt when the phone has no biometrics', () async {
      final auth = FakeAuthenticator(available: false);

      expect(await BiometricGuard(auth).confirm('Turn the light on'), isTrue);
      expect(auth.reasons, isEmpty, reason: 'no prompt is shown');
    });

    test('allows when nothing is enrolled or no screen lock is set', () async {
      for (final code in [
        auth_error.notEnrolled,
        auth_error.notAvailable,
        auth_error.passcodeNotSet,
      ]) {
        final guard = BiometricGuard(
          FakeAuthenticator(error: PlatformException(code: code)),
        );
        expect(await guard.confirm('x'), isTrue, reason: code);
      }
    });

    test('refuses when the user is locked out', () async {
      final guard = BiometricGuard(
        FakeAuthenticator(
          error: PlatformException(code: auth_error.lockedOut),
        ),
      );

      expect(await guard.confirm('Turn the pump off'), isFalse);
    });

    test('allows when the plugin is missing, as in tests', () async {
      final guard = BiometricGuard(
        FakeAuthenticator(error: MissingPluginException()),
      );

      expect(await guard.confirm('x'), isTrue);
    });
  });
}
