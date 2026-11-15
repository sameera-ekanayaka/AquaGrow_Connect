import 'package:aquagrow_mobile/data/local/preferences_store.dart';
import 'package:aquagrow_mobile/features/settings/application/theme_mode_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts in light mode when nothing is saved', () {
    expect(
      ThemeModeController(InMemoryPreferencesStore()).state,
      ThemeMode.light,
    );
  });

  test('remembers the chosen theme for the next launch', () async {
    final prefs = InMemoryPreferencesStore();
    await ThemeModeController(prefs).select(ThemeMode.dark);

    expect(prefs.getString(ThemeModeController.key), 'dark');
    expect(ThemeModeController(prefs).state, ThemeMode.dark);
  });

  test('falls back to light for an unknown saved value', () async {
    final prefs = InMemoryPreferencesStore();
    await prefs.setString(ThemeModeController.key, 'purple');
    expect(ThemeModeController(prefs).state, ThemeMode.light);
  });

  test('reload goes back to light after preferences are cleared', () async {
    final prefs = InMemoryPreferencesStore();
    final controller = ThemeModeController(prefs);
    await controller.select(ThemeMode.system);

    await prefs.clear();
    controller.reload();

    expect(controller.state, ThemeMode.light);
  });
}
