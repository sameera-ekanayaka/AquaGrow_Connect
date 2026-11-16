import 'package:aquagrow_mobile/features/auth/domain/app_lock_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const policy = AppLockPolicy();
  final left = DateTime(2026, 11, 16, 10);

  test('starts locked only when the lock is on', () {
    expect(policy.lockOnStart(enabled: true), isTrue);
    expect(policy.lockOnStart(enabled: false), isFalse);
  });

  test('locks again after a minute or more in the background', () {
    expect(
      policy.lockOnResume(
        enabled: true,
        backgroundedAt: left,
        now: left.add(const Duration(minutes: 1)),
      ),
      isTrue,
    );
    expect(
      policy.lockOnResume(
        enabled: true,
        backgroundedAt: left,
        now: left.add(const Duration(hours: 2)),
      ),
      isTrue,
    );
  });

  test('a quick switch to another app does not lock', () {
    expect(
      policy.lockOnResume(
        enabled: true,
        backgroundedAt: left,
        now: left.add(const Duration(seconds: 59)),
      ),
      isFalse,
    );
  });

  test('never locks when the lock is off', () {
    expect(
      policy.lockOnResume(
        enabled: false,
        backgroundedAt: left,
        now: left.add(const Duration(hours: 1)),
      ),
      isFalse,
    );
  });

  test('does not lock without a background time or if the clock went back', () {
    expect(
      policy.lockOnResume(enabled: true, backgroundedAt: null, now: left),
      isFalse,
    );
    expect(
      policy.lockOnResume(
        enabled: true,
        backgroundedAt: left,
        now: left.subtract(const Duration(minutes: 5)),
      ),
      isFalse,
    );
  });

  test('the timeout can be changed', () {
    const strict = AppLockPolicy(timeout: Duration.zero);
    expect(
      strict.lockOnResume(enabled: true, backgroundedAt: left, now: left),
      isTrue,
    );
  });
}
