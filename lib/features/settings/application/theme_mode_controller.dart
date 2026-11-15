import 'package:aquagrow_mobile/core/interfaces/i_preferences_store.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Light, dark or follow the phone, remembered across restarts.
class ThemeModeController extends StateNotifier<ThemeMode> {
  /// Starts with the saved choice in [preferences], or light if none.
  ThemeModeController(this._preferences) : super(_load(_preferences));

  /// Preference key that holds `light`, `dark` or `system`.
  static const key = 'theme_mode';

  final IPreferencesStore _preferences;

  /// Switches the theme and saves the choice.
  Future<void> select(ThemeMode mode) async {
    state = mode;
    await _preferences.setString(key, mode.name);
  }

  /// Reloads the saved choice, for example after local data was deleted.
  void reload() => state = _load(_preferences);

  static ThemeMode _load(IPreferencesStore preferences) {
    final saved = preferences.getString(key);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == saved,
      orElse: () => ThemeMode.light,
    );
  }
}

/// Light, dark or follow the phone. `AquaGrowApp` watches it; the Settings
/// screen changes it.
final themeModeProvider =
    StateNotifierProvider<ThemeModeController, ThemeMode>((ref) {
  return ThemeModeController(ref.watch(preferencesStoreProvider));
});
