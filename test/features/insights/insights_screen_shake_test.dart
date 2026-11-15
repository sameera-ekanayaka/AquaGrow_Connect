import 'dart:async';
import 'package:aquagrow_mobile/core/models/pod.dart';
import 'package:aquagrow_mobile/core/models/sensor_reading.dart';
import 'package:aquagrow_mobile/core/models/weather_data.dart';
import 'package:aquagrow_mobile/core/services/geo_service.dart';
import 'package:aquagrow_mobile/core/simulation/pod_simulator.dart';
import 'package:aquagrow_mobile/core/theme/app_theme.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/features/insights/application/history_providers.dart';
import 'package:aquagrow_mobile/features/insights/application/shake_detector_provider.dart';
import 'package:aquagrow_mobile/features/insights/domain/shake_math.dart';
import 'package:aquagrow_mobile/features/insights/presentation/insights_screen.dart';
import 'package:aquagrow_mobile/features/location/application/location_providers.dart';
import 'package:aquagrow_mobile/features/location/domain/location_access_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';

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

  group('InsightsScreen Shake to Refresh', () {
    late StreamController<AccelerometerEvent> sensorController;

    setUp(() {
      sensorController = StreamController<AccelerometerEvent>.broadcast();
    });

    tearDown(() async {
      await sensorController.close();
    });

    testWidgets(
      'shaking the device refreshes insights datasets and shows Refreshed notification',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        var historyFetches = 0;
        final sim = PodSimulator(clock: () => fixedClock);

        final container = ProviderContainer(
          overrides: [
            podSimulatorProvider.overrideWithValue(sim),
            clockProvider.overrideWithValue(() => fixedClock),
            selectedPodProvider.overrideWithValue(demoPod),
            shakeDetectorStreamProvider.overrideWithValue(
              sensorController.stream,
            ),
            shakeDetectorClockProvider.overrideWithValue(() => fixedClock),
            historyProvider.overrideWith((ref) {
              historyFetches++;
              return [
                SensorReading(
                  id: 'r1',
                  deviceId: 'pod-alpha',
                  ph: 6.0,
                  tdsPpm: 900,
                  ecMs: 1.8,
                  waterTempC: 22.0,
                  waterLevelPct: 80.0,
                  recordedAt: fixedClock,
                ),
              ];
            }),
            weatherDataProvider.overrideWith((ref) => sampleWeather),
            locationResultProvider.overrideWith(
              (ref) => LocationResult.granted(GeoPosition.defaultColombo),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.light,
              home: const Scaffold(body: InsightsScreen()),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(historyFetches, equals(1));
        expect(find.text('Refreshed'), findsNothing);

        // Sub-threshold movement (< 2.7g) does not trigger refresh
        sensorController.add(
          AccelerometerEvent(0, 0, ShakeMath.standardGravity * 1.5),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(historyFetches, equals(1));
        expect(find.text('Refreshed'), findsNothing);

        // Vigorous shake exceeding 2.7g triggers refresh
        sensorController.add(
          AccelerometerEvent(0, 0, ShakeMath.standardGravity * 3.2),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(historyFetches, equals(2));
        expect(find.text('Refreshed'), findsOneWidget);
      },
    );

    testWidgets(
      'multi-axis combined acceleration exceeding 2.7g triggers refresh',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        var historyFetches = 0;
        final sim = PodSimulator(clock: () => fixedClock);

        final container = ProviderContainer(
          overrides: [
            podSimulatorProvider.overrideWithValue(sim),
            clockProvider.overrideWithValue(() => fixedClock),
            selectedPodProvider.overrideWithValue(demoPod),
            shakeDetectorStreamProvider.overrideWithValue(
              sensorController.stream,
            ),
            shakeDetectorClockProvider.overrideWithValue(() => fixedClock),
            historyProvider.overrideWith((ref) {
              historyFetches++;
              return [];
            }),
            weatherDataProvider.overrideWith((ref) => sampleWeather),
            locationResultProvider.overrideWith(
              (ref) => LocationResult.granted(GeoPosition.defaultColombo),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.light,
              home: const Scaffold(body: InsightsScreen()),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(historyFetches, equals(1));

        // Combined 3D vector: x = 16 m/s^2, y = 16 m/s^2, z = 16 m/s^2
        // sqrt(256 * 3) = sqrt(768) ≈ 27.71 m/s^2
        // 27.71 / 9.80665 ≈ 2.82g > 2.7g
        sensorController.add(AccelerometerEvent(16.0, 16.0, 16.0));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(historyFetches, equals(2));
        expect(find.text('Refreshed'), findsOneWidget);
      },
    );

    testWidgets(
      'cancels shake detector subscription cleanly when screen is unmounted',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        var historyFetches = 0;
        final sim = PodSimulator(clock: () => fixedClock);

        final container = ProviderContainer(
          overrides: [
            podSimulatorProvider.overrideWithValue(sim),
            clockProvider.overrideWithValue(() => fixedClock),
            selectedPodProvider.overrideWithValue(demoPod),
            shakeDetectorStreamProvider.overrideWithValue(
              sensorController.stream,
            ),
            shakeDetectorClockProvider.overrideWithValue(() => fixedClock),
            historyProvider.overrideWith((ref) {
              historyFetches++;
              return [];
            }),
            weatherDataProvider.overrideWith((ref) => sampleWeather),
            locationResultProvider.overrideWith(
              (ref) => LocationResult.granted(GeoPosition.defaultColombo),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.light,
              home: const Scaffold(body: InsightsScreen()),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(historyFetches, equals(1));

        // Unmount InsightsScreen by replacing widget tree
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(body: Text('Different Screen')),
            ),
          ),
        );
        await tester.pump();

        // Shaking now must not trigger any further history fetches
        sensorController.add(
          AccelerometerEvent(0, 0, ShakeMath.standardGravity * 4.0),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(historyFetches, equals(1));
      },
    );
  });
}
