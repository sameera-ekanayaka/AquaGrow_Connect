import 'package:aquagrow_mobile/core/interfaces/i_share_service.dart';
import 'package:aquagrow_mobile/core/models/pod.dart';
import 'package:aquagrow_mobile/core/models/sensor_metric.dart';
import 'package:aquagrow_mobile/core/models/sensor_reading.dart';
import 'package:aquagrow_mobile/core/models/weather_data.dart';
import 'package:aquagrow_mobile/core/simulation/pod_simulator.dart';
import 'package:aquagrow_mobile/core/theme/app_theme.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/features/insights/application/history_providers.dart';
import 'package:aquagrow_mobile/features/insights/presentation/insights_screen.dart';
import 'package:aquagrow_mobile/features/location/application/location_providers.dart';
import 'package:aquagrow_mobile/features/location/presentation/vpd_gauge_card.dart';
import 'package:aquagrow_mobile/features/location/presentation/weather_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeShareService implements IShareService {
  String? sharedFileName;
  String? sharedMimeType;
  List<int>? sharedBytes;

  @override
  Future<void> shareText(String text, {String? subject}) async {}

  @override
  Future<void> shareBytes({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
    String? text,
  }) async {
    sharedBytes = bytes;
    sharedFileName = fileName;
    sharedMimeType = mimeType;
  }
}

void main() {
  final fixedClock = DateTime(2026, 11, 15, 10, 0);

  final sampleWeather = WeatherData(
    temperatureC: 28.0,
    relativeHumidityPct: 70.0,
    atmosphericPressureHpa: 1012.0,
    uvIndex: 5.0,
    windSpeedMps: 2.5,
    weatherCondition: 'Clear',
    weatherDescription: 'clear sky',
    iconCode: '01d',
    cityName: 'Colombo',
    countryCode: 'LK',
    latitude: 6.9271,
    longitude: 79.8612,
    sunriseTime: fixedClock.subtract(const Duration(hours: 4)),
    sunsetTime: fixedClock.add(const Duration(hours: 8)),
    recordedAt: fixedClock,
  );

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
            weatherDataProvider.overrideWith((ref) => sampleWeather),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(createWidgetUnderTest(container: container));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

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

        // Stats row under chart has stability info
        expect(find.textContaining('% in range'), findsOneWidget);

        // Embedded weather summary and VPD cards
        expect(find.byType(WeatherSummaryCard), findsOneWidget);
        expect(find.byType(VpdGaugeCard), findsOneWidget);

        // Microclimate controls navigation banner
        expect(find.text('Weather and VPD'), findsOneWidget);
      },
    );

    testWidgets(
      'switching to 7 days updates the historyRangeProvider and requests 7 days',
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
            weatherDataProvider.overrideWith((ref) => sampleWeather),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(createWidgetUnderTest(container: container));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Initially in 24 hours
        expect(
          container.read(historyRangeProvider),
          equals(HistoryRange.hours24),
        );

        // Tap 7 days button
        await tester.tap(find.text('7 days'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

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
            weatherDataProvider.overrideWith((ref) => sampleWeather),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(createWidgetUnderTest(container: container));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Initially pH
        expect(container.read(historyMetricProvider), equals(SensorMetric.ph));

        // Tap Nutrients (EC) chip
        await tester.tap(find.widgetWithText(FilterChip, 'Nutrients (EC)'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Verify metric changed to EC
        expect(container.read(historyMetricProvider), equals(SensorMetric.ec));
        expect(find.textContaining('mS/cm'), findsWidgets);
      },
    );

    testWidgets(
      'tapping export button triggers shareBytes with generated CSV',
      (tester) async {
        final sim = PodSimulator(clock: () => fixedClock);
        final fakeShare = _FakeShareService();
        final container = ProviderContainer(
          overrides: [
            podSimulatorProvider.overrideWithValue(sim),
            clockProvider.overrideWithValue(() => fixedClock),
            selectedPodProvider.overrideWithValue(demoPod),
            historyProvider.overrideWith((ref) => sampleReadings),
            weatherDataProvider.overrideWith((ref) => sampleWeather),
            shareServiceProvider.overrideWithValue(fakeShare),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(createWidgetUnderTest(container: container));
        await tester.pump();

        expect(find.byTooltip('Export readings'), findsOneWidget);
        await tester.tap(find.byTooltip('Export readings'));
        await tester.pump();

        expect(fakeShare.sharedFileName, contains('aquagrow_pod_alpha'));
        expect(fakeShare.sharedFileName, endsWith('.csv'));
        expect(fakeShare.sharedMimeType, 'text/csv');
        expect(fakeShare.sharedBytes, isNotNull);
      },
    );

    testWidgets(
      'tapping export button with empty history shows friendly SnackBar',
      (tester) async {
        final sim = PodSimulator(clock: () => fixedClock);
        final fakeShare = _FakeShareService();
        final container = ProviderContainer(
          overrides: [
            podSimulatorProvider.overrideWithValue(sim),
            clockProvider.overrideWithValue(() => fixedClock),
            selectedPodProvider.overrideWithValue(demoPod),
            historyProvider.overrideWith((ref) => const <SensorReading>[]),
            weatherDataProvider.overrideWith((ref) => sampleWeather),
            shareServiceProvider.overrideWithValue(fakeShare),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(createWidgetUnderTest(container: container));
        await tester.pump();

        await tester.tap(find.byTooltip('Export readings'));
        await tester.pump();

        expect(find.text('No readings to export yet'), findsOneWidget);
        expect(fakeShare.sharedBytes, isNull);
      },
    );
  });
}
