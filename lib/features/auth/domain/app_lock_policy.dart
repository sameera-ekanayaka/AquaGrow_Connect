/// When the optional app lock must ask the user to unlock, like WhatsApp's
/// "Fingerprint lock: automatically lock after 1 minute".
///
/// Pure Dart: the caller passes the times, so tests control the clock.
class AppLockPolicy {
  /// Creates the policy. The app re-locks after [timeout] in the background.
  const AppLockPolicy({this.timeout = const Duration(minutes: 1)});

  /// How long the app may stay in the background before it locks again.
  final Duration timeout;

  /// Whether the app starts locked: only when the lock is [enabled].
  bool lockOnStart({required bool enabled}) => enabled;

  /// Whether returning to the app at [now] must lock it, given when it went
  /// to the background ([backgroundedAt], null if it never did).
  ///
  /// Locks only if the lock is [enabled] and the app was away for at least
  /// [timeout]. A clock that moved backwards never locks.
  bool lockOnResume({
    required bool enabled,
    required DateTime? backgroundedAt,
    required DateTime now,
  }) {
    if (!enabled || backgroundedAt == null) return false;
    final away = now.difference(backgroundedAt);
    return !away.isNegative && away >= timeout;
  }
}
