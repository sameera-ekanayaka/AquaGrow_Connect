import 'package:aquagrow_mobile/core/interfaces/i_preferences_store.dart';
import 'package:hive/hive.dart';

/// Preferences saved in an open Hive box (normally `app_preferences`).
class HivePreferencesStore implements IPreferencesStore {
  /// Wraps an already opened [box].
  HivePreferencesStore(this._box);

  final Box<dynamic> _box;

  @override
  bool getBool(String key, {bool fallback = false}) {
    final value = _box.get(key);
    return value is bool ? value : fallback;
  }

  @override
  Future<void> setBool(String key, {required bool value}) =>
      _box.put(key, value);

  @override
  String? getString(String key) {
    final value = _box.get(key);
    return value is String ? value : null;
  }

  @override
  Future<void> setString(String key, String value) => _box.put(key, value);

  @override
  Future<void> clear() async {
    await _box.clear();
  }
}

/// Preferences kept in memory only. Used in tests and if Hive failed to open.
class InMemoryPreferencesStore implements IPreferencesStore {
  final Map<String, Object> _values = {};

  @override
  bool getBool(String key, {bool fallback = false}) {
    final value = _values[key];
    return value is bool ? value : fallback;
  }

  @override
  Future<void> setBool(String key, {required bool value}) async =>
      _values[key] = value;

  @override
  String? getString(String key) {
    final value = _values[key];
    return value is String ? value : null;
  }

  @override
  Future<void> setString(String key, String value) async =>
      _values[key] = value;

  @override
  Future<void> clear() async => _values.clear();
}
