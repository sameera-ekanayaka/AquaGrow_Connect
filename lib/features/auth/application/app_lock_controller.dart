import 'package:aquagrow_mobile/core/interfaces/i_preferences_store.dart';
import 'package:aquagrow_mobile/core/security/device_authenticator.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/features/auth/domain/app_lock_policy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Preference key that remembers whether the app lock is on.
const appLockPreferenceKey = 'app_lock_enabled';

/// Whether the app lock is on, and whether the app is locked right now.
class AppLockState {
  /// Creates a state.
  const AppLockState({required this.enabled, required this.locked});

  /// The user turned the app lock on in Settings.
  final bool enabled;

  /// The lock screen is showing and the app is hidden behind it.
  final bool locked;
}

/// The optional app lock, like WhatsApp's fingerprint lock (Settings >
/// Privacy > App lock).
///
/// When on, the app starts locked and locks again after a minute in the
/// background ([AppLockPolicy]). Unlocking uses the phone's own lock
/// (fingerprint, face, or the phone PIN), so AquaGrow never stores a
/// password. Off by default.
class AppLockController extends StateNotifier<AppLockState> {
  /// Creates the controller. [clock] gives the time (tests pass a fixed one).
  AppLockController({
    required IPreferencesStore preferences,
    required DeviceAuthenticator authenticator,
    DateTime Function()? clock,
    AppLockPolicy policy = const AppLockPolicy(),
  })  : _preferences = preferences,
        _authenticator = authenticator,
        _clock = clock ?? DateTime.now,
        _policy = policy,
        super(_initial(preferences, policy));

  final IPreferencesStore _preferences;
  final DeviceAuthenticator _authenticator;
  final DateTime Function() _clock;
  final AppLockPolicy _policy;

  DateTime? _backgroundedAt;
  bool _checking = false;

  static AppLockState _initial(IPreferencesStore prefs, AppLockPolicy policy) {
    final enabled = prefs.getBool(appLockPreferenceKey);
    return AppLockState(
      enabled: enabled,
      locked: policy.lockOnStart(enabled: enabled),
    );
  }

  /// Turns the lock on after the user passes the phone's check.
  ///
  /// Returns null when it is on, or a message saying why it is not.
  Future<String?> enable() async {
    switch (await checkDeviceUser(_authenticator, 'Turn on app lock')) {
      case DeviceCheck.unavailable:
        return 'Set up a fingerprint or screen lock on your phone first.';
      case DeviceCheck.failed:
        return 'App lock was not turned on.';
      case DeviceCheck.passed:
        await _preferences.setBool(appLockPreferenceKey, value: true);
        state = const AppLockState(enabled: true, locked: false);
        return null;
    }
  }

  /// Turns the lock off after the user passes the phone's check, so someone
  /// holding an unlocked phone cannot simply switch it off.
  ///
  /// If the phone no longer has any lock, it turns off without a prompt.
  /// Returns null when it is off, or a message saying why it is still on.
  Future<String?> disable() async {
    final check = await checkDeviceUser(_authenticator, 'Turn off app lock');
    if (check == DeviceCheck.failed) return 'App lock is still on.';
    await _preferences.setBool(appLockPreferenceKey, value: false);
    state = const AppLockState(enabled: false, locked: false);
    return null;
  }

  /// Call when the app goes to the background.
  void onBackground() => _backgroundedAt = _clock();

  /// Call when the app comes back. Locks it if it was away long enough.
  void onForeground() {
    final lock = _policy.lockOnResume(
      enabled: state.enabled,
      backgroundedAt: _backgroundedAt,
      now: _clock(),
    );
    _backgroundedAt = null;
    if (lock) state = const AppLockState(enabled: true, locked: true);
  }

  /// Shows the phone's prompt and unlocks the app if it passes.
  ///
  /// If the phone's own lock was removed after the app lock was turned on,
  /// the app unlocks instead of locking the user out. Returns true when
  /// unlocked.
  Future<bool> unlock() async {
    if (!state.locked) return true;
    if (_checking) return false;
    _checking = true;
    try {
      final check = await checkDeviceUser(_authenticator, 'Unlock AquaGrow');
      if (check == DeviceCheck.failed) return false;
      if (mounted) state = AppLockState(enabled: state.enabled, locked: false);
      return true;
    } finally {
      _checking = false;
    }
  }

  /// Reads the saved setting again, for example after "Delete my local data"
  /// cleared it.
  void reload() {
    final enabled = _preferences.getBool(appLockPreferenceKey);
    state = AppLockState(enabled: enabled, locked: state.locked && enabled);
  }
}

/// The app lock for the whole app.
final appLockProvider =
    StateNotifierProvider<AppLockController, AppLockState>((ref) {
  return AppLockController(
    preferences: ref.watch(preferencesStoreProvider),
    authenticator: ref.watch(deviceAuthenticatorProvider),
  );
});
