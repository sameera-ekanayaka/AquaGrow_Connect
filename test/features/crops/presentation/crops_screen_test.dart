import 'package:aquagrow_mobile/core/simulation/pod_simulator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

void main() {
  group('CropsScreen (My Pods)', () {
    late PodSimulator sim;

    setUp(() {
      sim = PodSimulator(clock: () => DateTime(2026, 11, 15, 10));
    });

    tearDown(() {
      sim.dispose();
    });

    testWidgets('renders two pod cards with crop names using testApp()',
        (tester) async {
      await tester.pumpWidget(testApp(sim: sim));
      await tester.pump();

      // Switch to Crops tab
      await tester.tap(find.widgetWithText(NavigationDestination, 'Crops'));
      await tester.pumpAndSettle();

      expect(find.text('My Pods'), findsOneWidget);
      expect(find.text('Genovese Basil'), findsOneWidget);
      expect(find.text('Baby Spinach'), findsOneWidget);
      expect(find.text('Add a pod'), findsOneWidget);
    });

    testWidgets('shows coming soon dialog when Add a pod is tapped',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(testApp(sim: sim));
      await tester.pump();

      await tester.tap(find.widgetWithText(NavigationDestination, 'Crops'));
      await tester.pumpAndSettle();

      final addBtn = find.text('Add a pod');
      await tester.ensureVisible(addBtn);
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Add a Pod'), findsOneWidget);
      expect(
        find.text(
          'Coming soon: Bluetooth and Wi-Fi pod pairing will be available in a future update.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('renders grid layout on wide screens (>= 600px)',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(testApp(sim: sim));
      await tester.pump();

      await tester.tap(find.widgetWithText(NavigationDestination, 'Crops'));
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('Genovese Basil'), findsOneWidget);
      expect(find.text('Baby Spinach'), findsOneWidget);
    });

    testWidgets('shows empty state when pods list is empty', (tester) async {
      await tester.pumpWidget(
        testApp(sim: sim),
      );
      await tester.pump();

      await tester.tap(find.widgetWithText(NavigationDestination, 'Crops'));
      await tester.pumpAndSettle();

      expect(find.text('My Pods'), findsOneWidget);
    });
  });
}
