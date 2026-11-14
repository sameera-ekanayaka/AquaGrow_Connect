import 'package:aquagrow_mobile/core/models/pod.dart';
import 'package:aquagrow_mobile/core/models/sensor_metric.dart';
import 'package:aquagrow_mobile/core/models/sensor_reading.dart';
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

  final demoPod = Pod(
    id: 'pod-alpha',
    name: 'Pod Alpha',
    room: 'Kitchen',
    isOnline: true,
    lastSeenAt: fixedClock,
  );

  final sampleReadings = [
    SensorReading(
      id: 'r1',
      deviceId: 'pod-alpha',
      ph: 6.2,
      tdsPpm: 900,
      ecMs: 1.8,
      waterTempC: 22.0,
      waterLevelPct: 80.0,
      recordedAt: fixedClock.subtract(const Duration(hours: 12)),
    ),
    SensorReading(
      id: 'r2',
      deviceId: 'pod-alpha',
      ph: 6.0,
      tdsPpm: 900,
      ecMs: 1.8,
      waterTempC: 21.5,
      waterLevelPct: 80.0,
      recordedAt: fixedClock.subtract(const Duration(hours: 1)),
    ),
  ];

  Widget createWidgetUnderTest({
    required ProviderContainer container,
  }) {
    return UncontrolledProviderScope(
      container: container,
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
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final sim = PodSimulator(clock: () => fixedClock);
        final container = ProviderContainer(
          overrides: [
            podSimulatorProvider.overrideWithValue(sim),
            clockProvider.overrideWithValue(() => fixedClock),
            selectedPodProvider.overrideWithValue(demoPod),
            historyProvider.overrideWith((ref) => sampleReadings),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(createWidgetUnderTest(container: container));
        await tester.pump();
        await tester.pump();

        // Screen title and pod display name in overline
        expect(find.text('Insights'), findsOneWidget);
        expect(find.textContaining('POD ALPHA'), findsOneWidget);

        // Metric chips are present
        expect(
          find.widgetWithText(FilterChip, 'pH'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(FilterChip, 'Nutrients (EC)'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(FilterChip, 'Water temp'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(FilterChip, 'Water level'),
          findsOneWidget,
        );

        // Range selector
        expect(find.text('24 hours'), findsOneWidget);
        expect(find.text('7 days'), findsOneWidget);

        // Weather and VPD banner
        expect(find.text('Weather and VPD'), findsOneWidget);

        // Stats row under chart has stability info
        expect(find.textContaining('% in range'), findsOneWidget);
      },
    );

    testWidgets(
      'switching to 7 days updates the historyRangeProvider and requests 7 days',
      (tester) async {
        final sim = PodSimulator(clock: () => fixedClock);
        final container = ProviderContainer(
          overrides: [
            podSimulatorProvider.overrideWithValue(sim),
            clockProvider.overrideWithValue(() => fixedClock),
            selectedPodProvider.overrideWithValue(demoPod),
            historyProvider.overrideWith((ref) => sampleReadings),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(createWidgetUnderTest(container: container));
        await tester.pump();
        await tester.pump();

        // Initially in 24 hours
        expect(
          container.read(historyRangeProvider),
          equals(HistoryRange.hours24),
        );

        // Tap 7 days button
        await tester.tap(find.text('7 days'));
        await tester.pump();
        await tester.pump();

        // Verify state transitioned to 7 days
        expect(
          container.read(historyRangeProvider),
          equals(HistoryRange.days7),
        );
      },
    );

    testWidgets(
      'switching metric chip updates the active graphed metric',
      (tester) async {
        final sim = PodSimulator(clock: () => fixedClock);
        final container = ProviderContainer(
          overrides: [
            podSimulatorProvider.overrideWithValue(sim),
            clockProvider.overrideWithValue(() => fixedClock),
            selectedPodProvider.overrideWithValue(demoPod),
            historyProvider.overrideWith((ref) => sampleReadings),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(createWidgetUnderTest(container: container));
        await tester.pump();
        await tester.pump();

        // Initially pH
        expect(container.read(historyMetricProvider), equals(SensorMetric.ph));

        // Tap Nutrients (EC) chip
        await tester.tap(find.widgetWithText(FilterChip, 'Nutrients (EC)'));
        await tester.pump();
        await tester.pump();

        // Verify metric changed to EC
        expect(container.read(historyMetricProvider), equals(SensorMetric.ec));
        expect(find.textContaining('mS/cm'), findsWidgets);
      },
    );
  });
}
