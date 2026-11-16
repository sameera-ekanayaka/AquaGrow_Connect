import 'package:aquagrow_mobile/core/simulation/pod_simulator.dart';
import 'package:aquagrow_mobile/features/alerts/presentation/alerts_screen.dart';
import 'package:aquagrow_mobile/features/auth/presentation/login_screen.dart';
import 'package:aquagrow_mobile/features/simulator/presentation/simulator_panel_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_notification_service.dart';
import '../helpers/test_app.dart';

/// Walks the live demo from docs/DEMO.md in one test, so a broken step
/// shows up in CI before it shows up in front of the examiners.
void main() {
  late PodSimulator sim;

  setUp(() {
    var now = DateTime(2026, 11, 15, 10);
    sim = PodSimulator(clock: () => now = now.add(const Duration(seconds: 2)));
  });
  tearDown(() => sim.dispose());

  /// Lets streams deliver and a page transition finish.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  /// The alerts bell in the tab header.
  final bell = find.byIcon(Icons.notifications_none);

  /// The unread number on the bell's badge.
  Finder badgeCount(String count) =>
      find.descendant(of: find.byType(Badge), matching: find.text(count));

  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(find.byTooltip(label));
    await settle(tester);
  }

  testWidgets('sign in, live Home, pH crash alert, Crops and Insights',
      (tester) async {
    final notifications = FakeNotificationService();
    await tester.pumpWidget(
      testApp(sim: sim, signedIn: false, notifications: notifications),
    );
    await settle(tester);

    // 1. Sign in with the demo account.
    expect(find.byType(LoginScreen), findsOneWidget);
    await tester.tap(find.byKey(const Key('login-demo')));
    await settle(tester);
    await settle(tester);

    // 2. Home shows both pods with live readings.
    expect(find.text('Your garden'), findsOneWidget);
    // The pod selector shows the name, then "Kitchen · updated ...".
    expect(find.text('Pod Alpha'), findsOneWidget);
    expect(find.textContaining('Kitchen · '), findsOneWidget);
    expect(bell, findsOneWidget);
    expect(badgeCount('1'), findsNothing);
    for (var i = 0; i < 3; i++) {
      sim.tick();
    }
    await settle(tester);

    // 3. Care > Pod simulator > pH crash.
    await openTab(tester, 'Care');
    await tester.tap(find.text('Pod simulator'));
    await settle(tester);
    expect(find.byType(SimulatorPanelScreen), findsOneWidget);
    final crash = find.text(SimScenario.acidSpike.label);
    await tester.ensureVisible(crash);
    await tester.tap(crash);
    await settle(tester);
    sim.tick();
    await settle(tester);

    // Back to Home: the pH tile reads 4.8 and the bell shows one alert.
    await tester.pageBack();
    await settle(tester);
    await openTab(tester, 'Home');
    expect(find.text('4.8'), findsOneWidget);
    expect(badgeCount('1'), findsOneWidget);
    expect(notifications.shown.map((a) => a.title), ['pH is too low']);

    // The bell opens Alerts with "pH is too low".
    await tester.tap(bell);
    await settle(tester);
    expect(find.byType(AlertsScreen), findsOneWidget);
    expect(find.text('pH is too low'), findsOneWidget);
    await tester.pageBack();
    await settle(tester);

    // 4. Crops lists the pods.
    await openTab(tester, 'Crops');
    expect(find.text('My Pods'), findsOneWidget);
    expect(find.text('Genovese Basil'), findsOneWidget);

    // 5. Insights shows charts, weather and VPD.
    await openTab(tester, 'Insights');
    expect(find.text('Insights').hitTestable(), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Weather and VPD'),
      300,
      scrollable: find.byType(Scrollable).hitTestable().first,
    );
    expect(find.text('Weather and VPD'), findsOneWidget);
  });
}
