import 'package:aquagrow_mobile/app/shell/notification_setup.dart';
import 'package:aquagrow_mobile/core/simulation/pod_simulator.dart';
import 'package:aquagrow_mobile/features/alerts/presentation/alerts_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_notification_service.dart';
import '../../../helpers/test_app.dart';

void main() {
  late PodSimulator sim;

  setUp(() => sim = PodSimulator(clock: () => DateTime(2026, 11, 15, 10)));
  tearDown(() => sim.dispose());

  testWidgets('explains why before asking for the notification permission',
      (tester) async {
    final notifications = FakeNotificationService(enabled: false);
    await tester.pumpWidget(testApp(sim: sim, notifications: notifications));
    await tester.pumpAndSettle();

    expect(find.text(NotificationSetup.explainTitle), findsOneWidget);
    expect(notifications.permissionRequests, 0);

    await tester.tap(find.text('Allow'));
    await tester.pumpAndSettle();

    expect(find.text(NotificationSetup.explainTitle), findsNothing);
    expect(notifications.permissionRequests, 1);
  });

  testWidgets('does not ask over onboarding on first launch', (tester) async {
    final notifications = FakeNotificationService(enabled: false);
    await tester.pumpWidget(
      testApp(
        sim: sim,
        notifications: notifications,
        signedIn: false,
        onboardingSeen: false,
        restoreDelay: const Duration(milliseconds: 300),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Skip'), findsOneWidget);
    expect(find.text(NotificationSetup.explainTitle), findsNothing);
    expect(notifications.permissionRequests, 0);

    // The one chance to ask is kept for after sign-in.
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use demo account'));
    await tester.pumpAndSettle();

    expect(find.text(NotificationSetup.explainTitle), findsOneWidget);
  });

  testWidgets('does not ask over login when signed out', (tester) async {
    final notifications = FakeNotificationService(enabled: false);
    await tester.pumpWidget(
      testApp(
        sim: sim,
        notifications: notifications,
        signedIn: false,
        restoreDelay: const Duration(milliseconds: 300),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Use demo account'), findsOneWidget);
    expect(find.text(NotificationSetup.explainTitle), findsNothing);
  });

  testWidgets('still asks after a slow restore when signed in', (tester) async {
    final notifications = FakeNotificationService(enabled: false);
    await tester.pumpWidget(
      testApp(
        sim: sim,
        notifications: notifications,
        restoreDelay: const Duration(milliseconds: 300),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(NotificationSetup.explainTitle), findsOneWidget);
  });

  testWidgets('shows no dialog when notifications are already allowed',
      (tester) async {
    await tester.pumpWidget(testApp(sim: sim));
    await tester.pumpAndSettle();

    expect(find.text(NotificationSetup.explainTitle), findsNothing);
  });

  testWidgets('a pH crash sends one notification, and tapping it opens Alerts',
      (tester) async {
    final notifications = FakeNotificationService();
    await tester.pumpWidget(testApp(sim: sim, notifications: notifications));
    await tester.pumpAndSettle();

    sim.applyScenario('pod-alpha', SimScenario.acidSpike);
    await tester.pumpAndSettle();

    expect(notifications.shown, hasLength(1));
    expect(notifications.shown.single.title, 'pH is too low');

    notifications.tap();
    await tester.pumpAndSettle();

    expect(find.byType(AlertsScreen), findsOneWidget);
    expect(find.text('pH is too low'), findsOneWidget);
  });
}
