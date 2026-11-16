import 'package:aquagrow_mobile/core/security/device_authenticator.dart';
import 'package:aquagrow_mobile/core/theme/app_theme.dart';
import 'package:aquagrow_mobile/data/local/preferences_store.dart';
import 'package:aquagrow_mobile/features/auth/application/app_lock_controller.dart';
import 'package:aquagrow_mobile/features/auth/presentation/app_lock_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthenticator implements DeviceAuthenticator {
  bool passes = true;
  int prompts = 0;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> authenticate(String reason) async {
    prompts++;
    return passes;
  }
}

void main() {
  late InMemoryPreferencesStore prefs;
  late _FakeAuthenticator auth;
  late DateTime now;

  setUp(() {
    prefs = InMemoryPreferencesStore();
    auth = _FakeAuthenticator();
    now = DateTime(2026, 11, 16, 10);
  });

  Future<AppLockController> pumpGate(
    WidgetTester tester, {
    bool enabled = true,
    bool active = true,
  }) async {
    await prefs.setBool(appLockPreferenceKey, value: enabled);
    final controller = AppLockController(
      preferences: prefs,
      authenticator: auth,
      clock: () => now,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appLockProvider.overrideWith((ref) => controller)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: AppLockGate(
            active: active,
            child: const Scaffold(body: Text('Your garden')),
          ),
        ),
      ),
    );
    await tester.pump();
    return controller;
  }

  testWidgets('with the lock off, the app opens straight away', (tester) async {
    await pumpGate(tester, enabled: false);

    expect(find.text('AquaGrow is locked'), findsNothing);
    expect(find.text('Your garden'), findsOneWidget);
    expect(auth.prompts, 0);
  });

  testWidgets('with the lock on, it starts locked and asks at once',
      (tester) async {
    auth.passes = false;
    await pumpGate(tester);

    expect(find.text('AquaGrow is locked'), findsOneWidget);
    expect(auth.prompts, 1, reason: 'the prompt opens by itself');
  });

  testWidgets('passing the check shows the app', (tester) async {
    await pumpGate(tester);
    await tester.pump();

    expect(find.text('AquaGrow is locked'), findsNothing);
    expect(find.text('Your garden'), findsOneWidget);
  });

  testWidgets('a cancelled check stays locked; Unlock tries again',
      (tester) async {
    auth.passes = false;
    await pumpGate(tester);
    await tester.pump();
    expect(find.text('AquaGrow is locked'), findsOneWidget);

    auth.passes = true;
    await tester.tap(find.byKey(const Key('app-lock-unlock')));
    await tester.pump();

    expect(find.text('AquaGrow is locked'), findsNothing);
    expect(auth.prompts, 2);
  });

  testWidgets('never locks while signed out', (tester) async {
    await pumpGate(tester, active: false);

    expect(find.text('AquaGrow is locked'), findsNothing);
  });

  testWidgets('a minute in the background locks again; a quick switch not',
      (tester) async {
    await pumpGate(tester);
    await tester.pump();
    expect(find.text('AquaGrow is locked'), findsNothing);

    // A quick switch to another app.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    now = now.add(const Duration(seconds: 10));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text('AquaGrow is locked'), findsNothing);

    // Away for two minutes.
    auth.passes = false;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    now = now.add(const Duration(minutes: 2));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();
    expect(find.text('AquaGrow is locked'), findsOneWidget);
  });
}
