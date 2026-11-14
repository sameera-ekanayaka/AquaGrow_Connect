import 'package:aquagrow_mobile/core/models/sensor_metric.dart';
import 'package:aquagrow_mobile/core/simulation/pod_simulator.dart';
import 'package:aquagrow_mobile/core/theme/app_theme.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/features/insights/application/history_providers.dart';
import 'package:aquagrow_mobile/features/insights/presentation/insights_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fixedClock = DateTime(2026, 11, 15, 10, 0);

  Widget createWidgetUnderTest({
    required PodSimulator sim,
    ProviderContainer? container,
  }) {
    return ProviderScope(
      parent: container,
      overrides: [
        podSimulatorProvider.overrideWithValue(sim),
        clockProvider.overrideWithValue(() => fixedClock),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: InsightsScreen()),
      ),
    );
  }

  group('InsightsScreen widget tests', () {
    testWidgets(
        'renders screen headers, metric chips, and initial 24-hour chart',
        (tester) async {
      final sim = PodSimulator(clock: () => fixedClock);

      await tester.pumpWidget(createWidgetUnderTest(sim: sim));
      await tester.pumpAndSettle();

      // Title and overline
      expect(find.text('Insights'), findsOneWidget);
      expect(
        find.textContaining('HOW YOUR PODS ARE DOING'),
        findsNothing,
      ); // Overline has pod name
      expect(find.textContaining('KITCHEN'), findsOneWidget);

      // Metric chips are present
      expect(find.text('pH'), findsOneWidget);
      expect(find.text('Nutrients (EC)'), findsOneWidget);
      expect(find.text('Water temp'), findsOneWidget);
      expect(find.text('Water level'), findsOneWidget);

      // Range selector
      expect(find.text('24 hours'), findsOneWidget);
      expect(find.text('7 days'), findsOneWidget);

      // Weather and VPD banner
      expect(find.text('Weather and VPD'), findsOneWidget);

      // Stats row under chart has stability info
      expect(find.textContaining('% in range'), findsOneWidget);
    });

    testWidgets(
        'switching to 7 days updates the historyRangeProvider and requests 7 days',
        (tester) async {
      final sim = PodSimulator(clock: () => fixedClock);
      final container = ProviderContainer(
        overrides: [
          podSimulatorProvider.overrideWithValue(sim),
          clockProvider.overrideWithValue(() => fixedClock),
        ],
      );
      addTearDown(container.dispose);

      await tester
          .pumpWidget(createWidgetUnderTest(sim: sim, container: container));
      await tester.pumpAndSettle();

      // Initially in 24 hours
      expect(
        container.read(historyRangeProvider),
        equals(HistoryRange.hours24),
      );

      // Tap 7 days button
      await tester.tap(find.text('7 days'));
      await tester.pumpAndSettle();

      // Verify state transitioned to 7 days
      expect(container.read(historyRangeProvider), equals(HistoryRange.days7));
    });

    testWidgets('switching metric chip updates the active graphed metric',
        (tester) async {
      final sim = PodSimulator(clock: () => fixedClock);
      final container = ProviderContainer(
        overrides: [
          podSimulatorProvider.overrideWithValue(sim),
          clockProvider.overrideWithValue(() => fixedClock),
        ],
      );
      addTearDown(container.dispose);

      await tester
          .pumpWidget(createWidgetUnderTest(sim: sim, container: container));
      await tester.pumpAndSettle();

      // Initially pH
      expect(container.read(historyMetricProvider), equals(SensorMetric.ph));

      // Tap Nutrients (EC) chip
      await tester.tap(find.text('Nutrients (EC)'));
      await tester.pumpAndSettle();

      // Verify metric changed to EC
      expect(container.read(historyMetricProvider), equals(SensorMetric.ec));
      expect(find.textContaining('mS/cm'), findsWidgets);
    });
  });
}
