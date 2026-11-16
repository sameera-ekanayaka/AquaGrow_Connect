import 'package:aquagrow_mobile/core/config/app_config.dart';
import 'package:aquagrow_mobile/core/mocks/mock_weather_service.dart';
import 'package:aquagrow_mobile/core/models/pod.dart';
import 'package:aquagrow_mobile/core/models/sensor_reading.dart';
import 'package:aquagrow_mobile/core/models/vpd_reading.dart';
import 'package:aquagrow_mobile/core/services/weather_service.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/features/location/application/location_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(
      'Weather and VPD providers configuration and live telemetry integration',
      () {
    test('weatherServiceProvider uses MockWeatherService when API key is empty',
        () {
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(
              supabaseUrl: '',
              supabaseAnonKey: '',
              openWeatherApiKey: '',
              requestedMode: DataMode.simulation,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(weatherServiceProvider);
      expect(service, isA<MockWeatherService>());
    });

    test(
        'weatherServiceProvider uses real WeatherService when API key is provided',
        () {
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(
              supabaseUrl: '',
              supabaseAnonKey: '',
              openWeatherApiKey: 'test-owm-api-key',
              requestedMode: DataMode.simulation,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(weatherServiceProvider);
      expect(service, isA<WeatherService>());
    });

    test(
        'vpdReadingProvider feeds dynamically from selected pod latest telemetry',
        () async {
      final liveReading = SensorReading(
        id: 'telemetry-now',
        deviceId: 'pod-alpha',
        ph: 6.0,
        tdsPpm: 900,
        ecMs: 1.8,
        waterTempC: 22.0,
        ambientTempC: 32.0,
        humidityPct: 45.0,
        waterLevelPct: 80.0,
        recordedAt: DateTime.now(),
      );

      final container = ProviderContainer(
        overrides: [
          selectedPodIdProvider.overrideWith((ref) => 'pod-alpha'),
          selectedPodProvider.overrideWith(
            (ref) => Pod(
              id: 'pod-alpha',
              name: 'Pod Alpha',
              room: 'Kitchen',
              isOnline: true,
              lastSeenAt: DateTime(2026, 11, 15),
            ),
          ),
          latestReadingProvider('pod-alpha')
              .overrideWith((ref) => Stream.value(liveReading)),
        ],
      );
      addTearDown(container.dispose);

      // Await first emission of latestReadingProvider so vpdReadingProvider reads the live telemetry
      await container.read(latestReadingProvider('pod-alpha').future);

      final vpd = container.read(vpdReadingProvider);
      expect(vpd.airTemperatureC, equals(32.0));
      expect(vpd.relativeHumidityPct, equals(45.0));
      expect(vpd.vpdKpa, greaterThan(1.5));
      expect(vpd.zone, equals(VpdZone.overTranspirationStress));
    });
  });
}
