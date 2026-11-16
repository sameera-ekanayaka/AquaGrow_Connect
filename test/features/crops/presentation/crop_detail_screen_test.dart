import 'package:aquagrow_mobile/core/simulation/pod_simulator.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/features/crops/presentation/crop_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CropDetailScreen', () {
    late PodSimulator sim;

    setUp(() {
      sim = PodSimulator(clock: () => DateTime(2026, 11, 15, 10));
    });

    tearDown(() {
      sim.dispose();
    });

    Future<void> pumpScreen(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            podSimulatorProvider.overrideWithValue(sim),
            podsProvider.overrideWith((ref) => Stream.value(sim.pods)),
          ],
          child: const MaterialApp(
            home: CropDetailScreen(podId: 'pod-alpha'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

    testWidgets(
        'renders crop hero, stage cards, recipe tiles and harvest button',
        (tester) async {
      await pumpScreen(tester);

      expect(find.text('Genovese Basil'), findsAtLeast(1));
      expect(find.text('Seedling'), findsOneWidget);
      expect(find.text('Growing'), findsAtLeast(1));
      expect(find.text('Ready to harvest'), findsOneWidget);
      expect(find.text('Recipe targets'), findsOneWidget);
      expect(find.text('pH'), findsOneWidget);
      expect(find.text('Nutrients (EC)'), findsOneWidget);
      expect(find.text('Water temp'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Harvest crop'), findsOneWidget);
    });

    testWidgets('shows confirmation dialog when Harvest crop is tapped',
        (tester) async {
      await pumpScreen(tester);

      final harvestBtn = find.text('Harvest crop');
      await tester.ensureVisible(harvestBtn);
      await tester.tap(harvestBtn);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });
  });
}
