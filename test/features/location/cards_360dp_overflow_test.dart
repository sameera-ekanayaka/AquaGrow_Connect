import 'package:aquagrow_mobile/core/models/vpd_reading.dart';
import 'package:aquagrow_mobile/core/models/weather_data.dart';
import 'package:aquagrow_mobile/core/theme/app_theme.dart';
import 'package:aquagrow_mobile/features/location/presentation/location_providers.dart';
import 'package:aquagrow_mobile/features/location/presentation/vpd_gauge_card.dart';
import 'package:aquagrow_mobile/features/location/presentation/weather_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WeatherSummaryCard & VpdGaugeCard 360dp responsiveness', () {
    final sampleWeather = WeatherData(
      temperatureC: 32.5,
      relativeHumidityPct: 88.0,
      atmosphericPressureHpa: 1012.0,
      uvIndex: 9.5,
      windSpeedMps: 4.2,
      weatherCondition: 'Thunderstorm with heavy rain',
      weatherDescription: 'thunderstorm with heavy rain',
      iconCode: '11d',
      cityName: 'Sri Jayawardenepura Kotte',
      countryCode: 'LK',
      latitude: 6.9271,
      longitude: 79.8612,
      sunriseTime: DateTime(2026, 11, 15, 6, 0),
      sunsetTime: DateTime(2026, 11, 15, 18, 0),
      recordedAt: DateTime(2026, 11, 15, 12, 0),
    );

    final sampleVpd = VpdReading(
      airTemperatureC: 28.5,
      relativeHumidityPct: 70.0,
      vpdKpa: 0.94,
      saturationVpKpa: 3.78,
      actualVpKpa: 2.84,
      zone: VpdZone.optimalVegetative,
      statusTitle: 'Just right',
      actionableAdvice: 'Perfect transpiration rate for leafy greens.',
      calculatedAt: DateTime(2026, 11, 15, 12, 0),
    );

    testWidgets(
        'renders cleanly on 360dp narrow phone without RenderFlex overflow',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          weatherDataProvider.overrideWith((ref) => sampleWeather),
          vpdReadingProvider.overrideWithValue(sampleVpd),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    WeatherSummaryCard(),
                    SizedBox(height: 16),
                    VpdGaugeCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Expect no RenderFlex yellow/black stripe overflow exceptions
      expect(tester.takeException(), isNull);
      expect(find.byType(WeatherSummaryCard), findsOneWidget);
      expect(find.byType(VpdGaugeCard), findsOneWidget);
    });
  });
}
