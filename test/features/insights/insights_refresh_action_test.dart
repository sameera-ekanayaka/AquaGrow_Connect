import 'package:aquagrow_mobile/core/models/weather_data.dart';
import 'package:aquagrow_mobile/core/services/geo_service.dart';
import 'package:aquagrow_mobile/features/insights/application/history_providers.dart';
import 'package:aquagrow_mobile/features/insights/application/insights_refresh_action.dart';
import 'package:aquagrow_mobile/features/location/domain/location_access_status.dart';
import 'package:aquagrow_mobile/features/location/presentation/location_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('refreshInsightsWithContainer', () {
    test('invalidates history, weather, and location providers', () async {
      var historyBuildCount = 0;
      var weatherBuildCount = 0;
      var locationBuildCount = 0;

      final container = ProviderContainer(
        overrides: [
          historyProvider.overrideWith((ref) async {
            historyBuildCount++;
            return [];
          }),
          weatherDataProvider.overrideWith((ref) async {
            weatherBuildCount++;
            return WeatherData(
              temperatureC: 25.0,
              relativeHumidityPct: 60.0,
              atmosphericPressureHpa: 1013.0,
              uvIndex: 5.0,
              windSpeedMps: 3.5,
              weatherCondition: 'Clear',
              weatherDescription: 'clear sky',
              iconCode: '01d',
              cityName: 'Colombo',
              countryCode: 'LK',
              latitude: 6.9271,
              longitude: 79.8612,
              sunriseTime: DateTime(2026, 11, 15, 6),
              sunsetTime: DateTime(2026, 11, 15, 18),
              recordedAt: DateTime(2026, 11, 15, 12),
            );
          }),
          locationResultProvider.overrideWith((ref) async {
            locationBuildCount++;
            return LocationResult.granted(GeoPosition.defaultColombo);
          }),
        ],
      );
      addTearDown(container.dispose);

      // Initial read triggers builds
      await container.read(historyProvider.future);
      await container.read(weatherDataProvider.future);
      await container.read(locationResultProvider.future);

      expect(historyBuildCount, equals(1));
      expect(weatherBuildCount, equals(1));
      expect(locationBuildCount, equals(1));

      // Invalidate via helper
      refreshInsightsWithContainer(container);

      // Subsequent read triggers rebuild
      await container.read(historyProvider.future);
      await container.read(weatherDataProvider.future);
      await container.read(locationResultProvider.future);

      expect(historyBuildCount, equals(2));
      expect(weatherBuildCount, equals(2));
      expect(locationBuildCount, equals(2));
    });
  });
}
