import 'package:aquagrow_mobile/core/logging/app_logger.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';

const _log = AppLogger('security');

/// The device's fingerprint, face or screen-lock check.
///
/// An interface so tests can use a fake instead of the real plugin.
abstract interface class BiometricAuthenticator {
  /// True if the phone can check the user (biometrics or a screen lock).
  Future<bool> isAvailable();

  /// Shows the system prompt with [reason] and returns true if it passed.
  Future<bool> authenticate(String reason);
}

/// [BiometricAuthenticator] backed by the `local_auth` plugin.
///
/// Allows the phone's PIN, pattern or password as a fallback, and keeps the
/// prompt open if the app is briefly paused (`stickyAuth`).
class LocalAuthAuthenticator implements BiometricAuthenticator {
  /// Wraps [auth], or a new [LocalAuthentication].
  LocalAuthAuthenticator([LocalAuthentication? auth])
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async =>
      await _auth.isDeviceSupported() && await _auth.canCheckBiometrics;

  @override
  Future<bool> authenticate(String reason) => _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(stickyAuth: true),
      );
}

/// Asks the user to prove it is them before a risky pod command
/// (pump, light, dosing). Lecture 9 / OWASP M3: insecure authentication.
///
/// Use it after `showConfirmDialog`:
///
/// ```dart
/// final guard = ref.read(biometricGuardProvider);
/// if (!await guard.confirm('Turn the pump off')) return;
/// ```
class BiometricGuard {
  /// Creates a guard that checks the user with [authenticator].
  BiometricGuard(this._authenticator);

  final BiometricAuthenticator _authenticator;

  /// Error codes meaning the phone simply has no way to check the user.
  static const _unavailable = {
    auth_error.notAvailable,
    auth_error.notEnrolled,
    auth_error.passcodeNotSet,
    auth_error.otherOperatingSystem,
  };

  /// Returns true if the user passed the check, or if the phone has no
  /// biometrics or screen lock at all, so the demo never blocks.
  ///
  /// Returns false if the user cancelled, failed, or is locked out.
  Future<bool> confirm(String reason) async {
    try {
      if (!await _authenticator.isAvailable()) {
        _log.info('No biometrics on this device, allowing: $reason');
        return true;
      }
      return await _authenticator.authenticate(reason);
    } on MissingPluginException {
      // No plugin (tests, unsupported platform): nothing to check with.
      return true;
    } on PlatformException catch (e) {
      if (_unavailable.contains(e.code)) return true;
      _log.warning('Biometric check refused (${e.code}): $reason');
      return false;
    }
  }
}

/// The app's [BiometricGuard]. Osanda's pump and light controls call
/// `confirm` before sending a command.
final biometricGuardProvider = Provider<BiometricGuard>((ref) {
  return BiometricGuard(LocalAuthAuthenticator());
});
