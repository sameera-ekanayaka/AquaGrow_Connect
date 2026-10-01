import 'dart:math' as math;
import '../interfaces/i_weather_service.dart';
import '../models/weather_data.dart';

/// Offline mock implementation of [IWeatherService].
/// Provides deterministic, hyper-local equatorial weather telemetry for Sri Lanka
/// without requiring internet access or active third-party API credentials.
class MockWeatherService implements IWeatherService {
  final math.Random _random;

  MockWeatherService({int? seed}) : _random = math.Random(seed ?? 42);

  @override
  Future<WeatherData> fetchWeather({
    required double latitude,
    required double longitude,
    String? apiKey,
  }) async {
    // Simulate slight network roundtrip latency (50ms)
    await Future.delayed(const Duration(milliseconds: 50));

    final now = DateTime.now();
    // Simulate natural diurnal temperature fluctuation around 28-32°C
    final hour = now.hour + (now.minute / 60.0);
    final tempOffset = math.sin((hour - 9) * math.pi / 12) * 3.5;
    final baseTemp = 28.5 + tempOffset;
    final humidity = (82.0 - (tempOffset * 3)).clamp(50.0, 95.0);

    return WeatherData(
      temperatureC: double.parse(baseTemp.toStringAsFixed(1)),
      relativeHumidityPct: double.parse(humidity.toStringAsFixed(1)),
      atmosphericPressureHpa: 1012.0 + (_random.nextDouble() * 2 - 1),
      uvIndex: (hour >= 10 && hour <= 15) ? 7.8 : 2.1,
      windSpeedMps: 2.8,
      weatherCondition: 'Partly Cloudy',
      weatherDescription: 'scattered clouds with mild humidity',
      iconCode: (hour >= 6 && hour < 18) ? '02d' : '02n',
      cityName: _resolveCityFromCoords(latitude, longitude),
      countryCode: 'LK',
      latitude: latitude,
      longitude: longitude,
      sunriseTime: DateTime(now.year, now.month, now.day, 6, 5),
      sunsetTime: DateTime(now.year, now.month, now.day, 18, 15),
      recordedAt: now,
    );
  }

  @override
  Future<WeatherData> fetchWeatherByCity({
    required String cityName,
    String? apiKey,
  }) async {
    double lat = 6.9271;
    double lon = 79.8612;

    final lower = cityName.toLowerCase();
    if (lower.contains('kandy')) {
      lat = 7.2906;
      lon = 80.6337;
    } else if (lower.contains('gampaha')) {
      lat = 7.0840;
      lon = 79.9926;
    }

    return fetchWeather(latitude: lat, longitude: lon, apiKey: apiKey);
  }

  String _resolveCityFromCoords(double lat, double lon) {
    if ((lat - 6.9271).abs() < 0.1 && (lon - 79.8612).abs() < 0.1) {
      return 'Colombo';
    }
    if ((lat - 7.2906).abs() < 0.15 && (lon - 80.6337).abs() < 0.15) {
      return 'Kandy';
    }
    if ((lat - 7.0840).abs() < 0.1 && (lon - 79.9926).abs() < 0.1) {
      return 'Gampaha';
    }
    return 'Colombo';
  }
}
