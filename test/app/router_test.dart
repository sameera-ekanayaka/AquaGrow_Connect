import 'package:aquagrow_mobile/app/router/app_router.dart';
import 'package:aquagrow_mobile/app/router/app_routes.dart';
import 'package:aquagrow_mobile/core/simulation/pod_simulator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  group('authRedirect', () {
    test('waits while the saved session is loading', () {
      expect(
        authRedirect(isRestored: false, isSignedIn: false, location: AppRoutes.home),
        isNull,
      );
    });

    test('sends signed-out users to login', () {
      expect(
        authRedirect(isRestored: true, isSignedIn: false, location: AppRoutes.home),
        AppRoutes.login,
      );
      expect(
        authRedirect(isRestored: true, isSignedIn: false, location: AppRoutes.register),
        isNull,
      );
    });

    test('sends signed-in users away from login', () {
      expect(
        authRedirect(isRestored: true, isSignedIn: true, location: AppRoutes.login),
        AppRoutes.home,
      );
      expect(
        authRedirect(isRestored: true, isSignedIn: true, location: AppRoutes.crops),
        isNull,
      );
    });
  });

  group('App shell', () {
    late PodSimulator sim;

    setUp(() => sim = PodSimulator(clock: () => DateTime(2026, 11, 15, 10)));
    tearDown(() => sim.dispose());

    testWidgets('signed-in user lands on Home with live readings', (tester) async {
      await tester.pumpWidget(testApp(sim: sim));
      await tester.pump();
      await tester.pump();

      expect(find.text('Your garden'), findsOneWidget);
      // The pod selector shows the name, then "Kitchen · updated ...".
      expect(find.text('Pod Alpha'), findsOneWidget);
      expect(find.textContaining('Kitchen · '), findsOneWidget);
      expect(find.text('pH'), findsOneWidget);
      expect(find.text('6.2'), findsOneWidget);
    });

    testWidgets('bottom navigation switches between the four tabs', (tester) async {
      await tester.pumpWidget(testApp(sim: sim));
      await tester.pump();

      await tester.tap(find.widgetWithText(NavigationDestination, 'Crops'));
      await tester.pump();
      await tester.pump();
      expect(find.text('My Pods'), findsOneWidget);
      expect(find.text('Genovese Basil'), findsOneWidget);

      await tester.tap(find.widgetWithText(NavigationDestination, 'Insights'));
      await tester.pump();
      expect(find.text('Weather and VPD'), findsOneWidget);

      await tester.tap(find.widgetWithText(NavigationDestination, 'Care'));
      await tester.pump();
      expect(find.text('Pod simulator'), findsOneWidget);

      await tester.tap(find.widgetWithText(NavigationDestination, 'Home'));
      await tester.pump();
      expect(find.text('Your garden'), findsOneWidget);
    });

    testWidgets('a pH crash from the simulator turns the reading critical', (tester) async {
      await tester.pumpWidget(testApp(sim: sim));
      await tester.pump();

      sim.applyScenario('pod-alpha', SimScenario.acidSpike);
      await tester.pump();

      expect(find.text('4.8'), findsOneWidget);
    });

    testWidgets('signed-out user sees the login screen', (tester) async {
      await tester.pumpWidget(testApp(sim: sim, signedIn: false));
      await tester.pump(); // saved session restored: no user
      await tester.pump(const Duration(seconds: 1)); // finish the page transition

      expect(find.text('Your garden'), findsNothing);
      expect(find.byType(NavigationBar), findsNothing);
    });
  });
}
