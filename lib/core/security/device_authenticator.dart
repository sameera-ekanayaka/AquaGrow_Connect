import 'package:aquagrow_mobile/core/logging/app_logger.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';

const _log = AppLogger('security');

/// The phone's own lock: fingerprint or face, with the phone's PIN, pattern
/// or password as a fallback. AquaGrow never stores a password of its own.
///
/// An interface so tests can use a fake instead of the real plugin.
abstract interface class DeviceAuthenticator {
  /// True if the phone can check the user (biometrics or a screen lock).
  Future<bool> isAvailable();

  /// Shows the system prompt with [reason] and returns true if it passed.
  Future<bool> authenticate(String reason);
}

/// [DeviceAuthenticator] backed by the `local_auth` plugin.
class LocalAuthAuthenticator implements DeviceAuthenticator {
  /// Wraps [auth], or a new [LocalAuthentication].
  LocalAuthAuthenticator([LocalAuthentication? auth])
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() => _auth.isDeviceSupported();

  @override
  Future<bool> authenticate(String reason) => _auth.authenticate(
        localizedReason: reason,
        // Keep the prompt if the app is briefly paused; allow the phone PIN.
        options: const AuthenticationOptions(stickyAuth: true),
      );
}

/// The result of asking the phone to check the user.
enum DeviceCheck {
  /// The user passed the fingerprint, face or screen-lock check.
  passed,

  /// The user cancelled, failed, or is locked out.
  failed,

  /// The phone has no biometrics and no screen lock, so nothing can be checked.
  unavailable,
}

/// Error codes meaning the phone simply has no way to check the user.
const _unavailableCodes = {
  auth_error.notAvailable,
  auth_error.notEnrolled,
  auth_error.passcodeNotSet,
  auth_error.otherOperatingSystem,
};

/// Asks [authenticator] to check the user, showing [reason] in the prompt.
///
/// Never throws: plugin errors become [DeviceCheck.unavailable] (no lock set
/// up, or no plugin as in tests) or [DeviceCheck.failed] (for example, too
/// many attempts).
Future<DeviceCheck> checkDeviceUser(
  DeviceAuthenticator authenticator,
  String reason,
) async {
  try {
    if (!await authenticator.isAvailable()) return DeviceCheck.unavailable;
    return await authenticator.authenticate(reason)
        ? DeviceCheck.passed
        : DeviceCheck.failed;
  } on MissingPluginException {
    return DeviceCheck.unavailable;
  } on PlatformException catch (e) {
    if (_unavailableCodes.contains(e.code)) return DeviceCheck.unavailable;
    _log.warning('Device check refused (${e.code}): $reason');
    return DeviceCheck.failed;
  }
}

/// The phone-lock checker used by the app lock.
final deviceAuthenticatorProvider = Provider<DeviceAuthenticator>((ref) {
  return LocalAuthAuthenticator();
});
