import 'package:aquagrow_mobile/core/models/sensor_metric.dart';
import 'package:aquagrow_mobile/core/models/sensor_reading.dart';
import 'package:aquagrow_mobile/core/theme/app_theme.dart';
import 'package:aquagrow_mobile/features/insights/application/history_providers.dart';
import 'package:aquagrow_mobile/features/insights/domain/history_stats.dart';
import 'package:aquagrow_mobile/features/insights/presentation/widgets/telemetry_history_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 15, 10, 0);

  final sampleReadings = [
    SensorReading(
      id: 'r1',
      deviceId: 'pod-alpha',
      ph: 6.0,
      tdsPpm: 800,
      ecMs: 1.5,
      waterTempC: 22.0,
      waterLevelPct: 80.0,
      recordedAt: now.subtract(const Duration(hours: 6)),
    ),
    SensorReading(
      id: 'r2',
      deviceId: 'pod-alpha',
      ph: 6.2,
      tdsPpm: 850,
      ecMs: 1.7,
      waterTempC: 22.5,
      waterLevelPct: 78.0,
      recordedAt: now.subtract(const Duration(hours: 2)),
    ),
  ];

  Widget buildChartUnderTest({
    required SensorMetric metric,
    required HistoryRange range,
  }) {
    final stats = HistoryStats.compute(sampleReadings, metric);
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SingleChildScrollView(
          child: TelemetryHistoryChart(
            readings: sampleReadings,
            metric: metric,
            range: range,
            stats: stats,
          ),
        ),
      ),
    );
  }

  group('TelemetryHistoryChart axis formatting', () {
    testWidgets(
        'EC chart renders clean single-line numeric Y-axis labels without wrapping',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildChartUnderTest(
          metric: SensorMetric.ec,
          range: HistoryRange.hours24,
        ),
      );
      await tester.pumpAndSettle();

      // EC target badge and stat row display units
      expect(find.text('Target 1.2–2.4 mS/cm'), findsOneWidget);
      expect(find.textContaining('Avg 1.6 mS/cm'), findsOneWidget);

      // Y-axis ticks are clean numbers (e.g. 1.0, 1.5, 2.0, 2.5) without multi-line wrapping
      expect(find.text('1.0'), findsOneWidget);
      expect(find.text('1.5'), findsOneWidget);
      expect(find.text('2.0'), findsOneWidget);

      // No unformatted or unaligned min/max collision ticks (0.9, 2.7)
      expect(find.text('0.9'), findsNothing);
      expect(find.text('2.7'), findsNothing);
    });

    testWidgets('pH chart renders cleanly on 360dp width', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildChartUnderTest(
          metric: SensorMetric.ph,
          range: HistoryRange.days7,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Target 5.5–6.5'), findsOneWidget);
      expect(find.text('6.0'), findsOneWidget);
    });
  });
}
