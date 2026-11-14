import 'package:aquagrow_mobile/data/local/preferences_store.dart';
import 'package:aquagrow_mobile/features/alerts/application/notification_permission.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_notification_service.dart';

void main() {
  late FakeNotificationService service;
  late InMemoryPreferencesStore prefs;
  late NotificationPermissionFlow flow;
  late int explained;

  setUp(() {
    service = FakeNotificationService(enabled: false);
    prefs = InMemoryPreferencesStore();
    flow = NotificationPermissionFlow(service: service, preferences: prefs);
    explained = 0;
  });

  Future<bool> Function() answer(bool yes) => () async {
        explained++;
        return yes;
      };

  test('does nothing when notifications are already allowed', () async {
    service.enabled = true;
    expect(await flow.run(explain: answer(true)), isTrue);
    expect(explained, 0);
    expect(service.permissionRequests, 0);
  });

  test('explains first, then shows the system prompt when the user agrees',
      () async {
    expect(await flow.run(explain: answer(true)), isTrue);
    expect(explained, 1);
    expect(service.permissionRequests, 1);
  });

  test('skips the system prompt when the user says not now', () async {
    expect(await flow.run(explain: answer(false)), isFalse);
    expect(explained, 1);
    expect(service.permissionRequests, 0);
  });

  test('never asks twice, even after a refusal', () async {
    await flow.run(explain: answer(false));
    expect(await flow.run(explain: answer(true)), isFalse);
    expect(explained, 1);
    expect(prefs.getBool(NotificationPermissionFlow.askedKey), isTrue);
  });

  test('returns false when the system prompt is denied', () async {
    service.grant = false;
    expect(await flow.run(explain: answer(true)), isFalse);
    expect(service.permissionRequests, 1);
  });
}
