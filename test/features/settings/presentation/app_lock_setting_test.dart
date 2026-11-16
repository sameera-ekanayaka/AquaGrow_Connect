import 'package:aquagrow_mobile/core/interfaces/i_local_data_eraser.dart';
import 'package:aquagrow_mobile/core/security/device_authenticator.dart';
import 'package:aquagrow_mobile/core/theme/app_theme.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/data/local/preferences_store.dart';
import 'package:aquagrow_mobile/features/auth/application/app_lock_controller.dart';
import 'package:aquagrow_mobile/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthenticator implements DeviceAuthenticator {
  bool available = true;
  bool passes = true;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate(String reason) async => passes;
}

class _FakeEraser implements ILocalDataEraser {
  _FakeEraser(this.prefs);

  final InMemoryPreferencesStore prefs;

  @override
  Future<void> eraseAll() => prefs.clear();
}

void main() {
  late InMemoryPreferencesStore prefs;
  late _FakeAuthenticator auth;
  late ProviderContainer container;

  setUp(() {
    prefs = InMemoryPreferencesStore();
    auth = _FakeAuthenticator();
    container = ProviderContainer(
      overrides: [
        preferencesStoreProvider.overrideWithValue(prefs),
        deviceAuthenticatorProvider.overrideWithValue(auth),
        localDataEraserProvider.overrideWithValue(_FakeEraser(prefs)),
      ],
    );
  });

  tearDown(() => container.dispose());

  Future<void> pumpSettings(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  bool switchOn(WidgetTester tester) => tester
      .widget<SwitchListTile>(find.byKey(const Key('settings-app-lock')))
      .value;

  Future<void> toggle(WidgetTester tester) async {
    final tile = find.byKey(const Key('settings-app-lock'));
    await tester.ensureVisible(tile);
    await tester.tap(tile);
    await tester.pumpAndSettle();
  }

  testWidgets('App lock is off by default', (tester) async {
    await pumpSettings(tester);

    expect(find.text('App lock'), findsOneWidget);
    expect(switchOn(tester), isFalse);
  });

  testWidgets('turning it on after the phone check saves it', (tester) async {
    await pumpSettings(tester);

    await toggle(tester);

    expect(switchOn(tester), isTrue);
    expect(find.text('App lock is on'), findsOneWidget);
    expect(prefs.getBool(appLockPreferenceKey), isTrue);
  });

  testWidgets('without a phone lock it explains and stays off', (tester) async {
    auth.available = false;
    await pumpSettings(tester);

    await toggle(tester);

    expect(switchOn(tester), isFalse);
    expect(find.textContaining('screen lock on your phone'), findsOneWidget);
  });

  testWidgets('turning it off needs the phone check too', (tester) async {
    await pumpSettings(tester);
    await toggle(tester);
    expect(switchOn(tester), isTrue);

    auth.passes = false;
    await toggle(tester);
    expect(switchOn(tester), isTrue);
    expect(find.text('App lock is still on.'), findsOneWidget);

    auth.passes = true;
    await toggle(tester);
    expect(switchOn(tester), isFalse);
  });

  testWidgets('Delete my local data also turns the lock off', (tester) async {
    await pumpSettings(tester);
    await toggle(tester);
    expect(switchOn(tester), isTrue);

    final delete = find.text('Delete my local data');
    await tester.ensureVisible(delete);
    await tester.tap(delete);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    // The switch has scrolled out of view, so check the lock itself.
    expect(container.read(appLockProvider).enabled, isFalse);
    expect(prefs.getBool(appLockPreferenceKey), isFalse);
  });
}
