import 'package:aquagrow_mobile/core/simulation/pod_simulator.dart';
import 'package:aquagrow_mobile/features/crops/presentation/crop_detail_screen.dart';
import 'package:aquagrow_mobile/features/crops/presentation/harvest_passport_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

/// Demo step 4 (docs/DEMO.md): Crops > Pod Alpha > Harvest opens the
/// Harvest Passport. The route was once missing, so the app showed
/// "page not found" instead; this keeps it from coming back.
void main() {
  late PodSimulator sim;

  setUp(() {
    var now = DateTime(2026, 11, 15, 10);
    sim = PodSimulator(clock: () => now = now.add(const Duration(seconds: 2)));
  });
  tearDown(() => sim.dispose());

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('confirming Harvest on crop detail opens the Harvest Passport',
      (tester) async {
    // A phone-sized screen (1080 x 2400 at 2.5x), like the demo phone.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(testApp(sim: sim));
    await settle(tester);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Crops'));
    await settle(tester);
    await tester.tap(find.text('Genovese Basil').first);
    await settle(tester);
    expect(find.byType(CropDetailScreen), findsOneWidget);

    final harvest = find.text('Harvest crop');
    await tester.scrollUntilVisible(
      harvest,
      200,
      scrollable: find
          .descendant(
            of: find.byType(CropDetailScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(harvest);
    await settle(tester);
    await tester.tap(harvest);
    await settle(tester);

    final confirm = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(FilledButton),
    );
    expect(confirm, findsOneWidget);
    await tester.tap(confirm);
    await settle(tester);

    expect(find.byType(HarvestPassportScreen), findsOneWidget);
    expect(find.textContaining('not found'), findsNothing);
  });
}
