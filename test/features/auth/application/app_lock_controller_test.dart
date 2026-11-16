import 'package:aquagrow_mobile/core/security/device_authenticator.dart';
import 'package:aquagrow_mobile/data/local/preferences_store.dart';
import 'package:aquagrow_mobile/features/auth/application/app_lock_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// A phone lock whose answers the test sets.
class FakeAuthenticator implements DeviceAuthenticator {
  bool available = true;
  bool passes = true;
  final reasons = <String>[];

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate(String reason) async {
    reasons.add(reason);
    return passes;
  }
}

void main() {
  late InMemoryPreferencesStore prefs;
  late FakeAuthenticator auth;
  late DateTime now;

  setUp(() {
    prefs = InMemoryPreferencesStore();
    auth = FakeAuthenticator();
    now = DateTime(2026, 11, 16, 10);
  });

  AppLockController create() => AppLockController(
        preferences: prefs,
        authenticator: auth,
        clock: () => now,
      );

  test('is off and unlocked by default', () {
    final lock = create();

    expect(lock.state.enabled, isFalse);
    expect(lock.state.locked, isFalse);
  });

  test('turning it on needs the phone check and is remembered', () async {
    final lock = create();

    expect(await lock.enable(), isNull);
    expect(lock.state.enabled, isTrue);
    expect(lock.state.locked, isFalse, reason: 'just proved it is you');
    expect(auth.reasons, ['Turn on app lock']);

    final restarted = create();
    expect(restarted.state.enabled, isTrue);
    expect(restarted.state.locked, isTrue, reason: 'locked on start');
  });

  test('cannot be turned on without a phone lock', () async {
    auth.available = false;
    final lock = create();

    expect(await lock.enable(), contains('screen lock'));
    expect(lock.state.enabled, isFalse);
  });

  test('stays off when the check is cancelled', () async {
    auth.passes = false;
    final lock = create();

    expect(await lock.enable(), 'App lock was not turned on.');
    expect(lock.state.enabled, isFalse);
  });

  test('locks again after a minute in the background', () async {
    final lock = create();
    await lock.enable();

    lock.onBackground();
    now = now.add(const Duration(minutes: 2));
    lock.onForeground();

    expect(lock.state.locked, isTrue);
  });

  test('a quick app switch stays unlocked', () async {
    final lock = create();
    await lock.enable();

    lock.onBackground();
    now = now.add(const Duration(seconds: 20));
    lock.onForeground();

    expect(lock.state.locked, isFalse);
  });

  test('never locks when it is off', () {
    final lock = create();

    lock.onBackground();
    now = now.add(const Duration(hours: 3));
    lock.onForeground();

    expect(lock.state.locked, isFalse);
  });

  test('unlock passes with the phone check and fails when cancelled', () async {
    await prefs.setBool(appLockPreferenceKey, value: true);
    final lock = create();
    expect(lock.state.locked, isTrue);

    auth.passes = false;
    expect(await lock.unlock(), isFalse);
    expect(lock.state.locked, isTrue);

    auth.passes = true;
    expect(await lock.unlock(), isTrue);
    expect(lock.state.locked, isFalse);
    expect(auth.reasons.last, 'Unlock AquaGrow');
  });

  test('unlocks if the phone lock was removed, instead of locking out',
      () async {
    await prefs.setBool(appLockPreferenceKey, value: true);
    auth.available = false;
    final lock = create();

    expect(await lock.unlock(), isTrue);
    expect(lock.state.locked, isFalse);
  });

  test('turning it off needs the phone check', () async {
    final lock = create();
    await lock.enable();

    auth.passes = false;
    expect(await lock.disable(), 'App lock is still on.');
    expect(lock.state.enabled, isTrue);

    auth.passes = true;
    expect(await lock.disable(), isNull);
    expect(lock.state.enabled, isFalse);
    expect(create().state.enabled, isFalse, reason: 'remembered');
  });

  test('reload follows a cleared preference', () async {
    final lock = create();
    await lock.enable();

    await prefs.clear();
    lock.reload();

    expect(lock.state.enabled, isFalse);
    expect(lock.state.locked, isFalse);
  });
}
