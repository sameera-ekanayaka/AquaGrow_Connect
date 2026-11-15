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

    testWidgets(
        'renders crop hero, stage timeline, recipe targets, and harvest button for pod-alpha',
        (tester) async {
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

      expect(find.text('Crop Detail'), findsOneWidget);
      expect(find.text('Genovese Basil'), findsAtLeast(1));
      expect(find.text('Growth Stages'), findsOneWidget);
      expect(find.text('Progress'), findsOneWidget);
      expect(find.text('Recipe Targets'), findsOneWidget);
      expect(find.text("Today's Average (24h)"), findsOneWidget);
      expect(find.text('Harvest Crop'), findsOneWidget);
    });

    testWidgets('shows confirmation dialog when Harvest Crop is tapped',
        (tester) async {
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

      final harvestBtn = find.text('Harvest Crop');
      await tester.ensureVisible(harvestBtn);
      await tester.tap(harvestBtn);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });
  });
}
