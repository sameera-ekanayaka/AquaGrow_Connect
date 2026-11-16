import 'package:aquagrow_mobile/core/security/device_authenticator.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

/// A fake phone lock with a scripted answer.
class FakeAuthenticator implements DeviceAuthenticator {
  FakeAuthenticator({this.available = true, this.passes = true, this.error});

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
  group('checkDeviceUser', () {
    test('passes when the user passes the prompt', () async {
      final auth = FakeAuthenticator();

      expect(
        await checkDeviceUser(auth, 'Unlock AquaGrow'),
        DeviceCheck.passed,
      );
      expect(auth.reasons, ['Unlock AquaGrow']);
    });

    test('fails when the user cancels or fails', () async {
      expect(
        await checkDeviceUser(FakeAuthenticator(passes: false), 'x'),
        DeviceCheck.failed,
      );
    });

    test('is unavailable without a prompt when the phone has no lock',
        () async {
      final auth = FakeAuthenticator(available: false);

      expect(await checkDeviceUser(auth, 'x'), DeviceCheck.unavailable);
      expect(auth.reasons, isEmpty);
    });

    test('nothing enrolled or no screen lock count as unavailable', () async {
      for (final code in [
        auth_error.notEnrolled,
        auth_error.notAvailable,
        auth_error.passcodeNotSet,
      ]) {
        final auth = FakeAuthenticator(error: PlatformException(code: code));
        expect(
          await checkDeviceUser(auth, 'x'),
          DeviceCheck.unavailable,
          reason: code,
        );
      }
    });

    test('a locked-out user fails', () async {
      final auth = FakeAuthenticator(
        error: PlatformException(code: auth_error.lockedOut),
      );

      expect(await checkDeviceUser(auth, 'x'), DeviceCheck.failed);
    });

    test('a missing plugin, as in tests, is unavailable', () async {
      final auth = FakeAuthenticator(error: MissingPluginException());

      expect(await checkDeviceUser(auth, 'x'), DeviceCheck.unavailable);
    });
  });
}
