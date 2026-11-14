/// Small app settings kept on the device, such as the theme or whether the
/// notification permission was already asked for.
///
/// Implementations:
/// - `HivePreferencesStore` (lib/data/local): the Hive `app_preferences` box.
/// - `InMemoryPreferencesStore` (lib/data/local): for tests, or when Hive
///   failed to open.
///
/// Never store tokens or personal data here: use secure storage for those.
abstract interface class IPreferencesStore {
  /// The saved flag for [key], or [fallback] if nothing is saved.
  bool getBool(String key, {bool fallback = false});

  /// Saves a flag.
  Future<void> setBool(String key, {required bool value});

  /// The saved text for [key], or null.
  String? getString(String key);

  /// Saves a piece of text.
  Future<void> setString(String key, String value);

  /// Deletes every saved preference.
  Future<void> clear();
}
