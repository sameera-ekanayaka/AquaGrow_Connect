import 'package:aquagrow_mobile/core/config/app_info.dart';
import 'package:aquagrow_mobile/core/interfaces/i_local_data_eraser.dart';
import 'package:aquagrow_mobile/core/theme/app_theme.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/data/local/preferences_store.dart';
import 'package:aquagrow_mobile/features/settings/application/theme_mode_controller.dart';
import 'package:aquagrow_mobile/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Counts calls instead of touching Hive.
class _FakeEraser implements ILocalDataEraser {
  _FakeEraser(this.prefs);

  final InMemoryPreferencesStore prefs;
  int calls = 0;

  @override
  Future<void> eraseAll() async {
    calls++;
    await prefs.clear();
  }
}

void main() {
  late InMemoryPreferencesStore prefs;
  late _FakeEraser eraser;
  late ProviderContainer container;

  setUp(() {
    prefs = InMemoryPreferencesStore();
    eraser = _FakeEraser(prefs);
    container = ProviderContainer(
      overrides: [
        preferencesStoreProvider.overrideWithValue(prefs),
        localDataEraserProvider.overrideWithValue(eraser),
      ],
    );
  });

  tearDown(() => container.dispose());

  Future<void> pumpSettings(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Scrolls to the delete button and taps it.
  Future<void> tapDelete(WidgetTester tester) async {
    final button = find.widgetWithText(OutlinedButton, 'Delete my local data');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
  }

  testWidgets('shows the data mode, version, privacy note and team',
      (tester) async {
    await pumpSettings(tester);

    expect(find.text('Simulation'), findsOneWidget);
    expect(find.text(AppInfo.versionLabel), findsOneWidget);
    expect(find.text('On this phone'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Built by'), 200);
    expect(find.text(AppInfo.team.join(', ')), findsOneWidget);
    expect(find.text(AppInfo.module), findsOneWidget);
  });

  testWidgets('choosing Dark switches and remembers the theme', (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(prefs.getString(ThemeModeController.key), 'dark');
  });

  testWidgets('cancelling the delete dialog keeps local data', (tester) async {
    await pumpSettings(tester);
    await tapDelete(tester);
    await tester.pumpAndSettle();
    expect(find.text('Delete local data?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(eraser.calls, 0);
  });

  testWidgets('confirming deletes local data and resets the theme',
      (tester) async {
    await pumpSettings(tester);
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    await tapDelete(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(eraser.calls, 1);
    expect(container.read(themeModeProvider), ThemeMode.light);
    expect(find.text('Local data deleted'), findsOneWidget);
  });
}
