import 'dart:math' as math;

import 'package:aquagrow_mobile/core/interfaces/i_weather_service.dart';
import 'package:aquagrow_mobile/core/mocks/mock_weather_service.dart';
import 'package:aquagrow_mobile/core/models/weather_data.dart';

/// Offline mock implementation of [IWeatherService] with zero artificial latency,
/// ensuring widget tests and simulation mode remain completely free of pending timers.
class InstantMockWeatherService extends MockWeatherService {
  InstantMockWeatherService({super.seed});

  @override
  Future<WeatherData> fetchWeather({
    required double latitude,
    required double longitude,
    String? apiKey,
  }) async {
    final now = DateTime.now();
    final hour = now.hour + (now.minute / 60.0);
    final tempOffset = math.sin((hour - 9) * math.pi / 12) * 3.5;
    final baseTemp = 28.5 + tempOffset;
    final humidity = (82.0 - (tempOffset * 3)).clamp(50.0, 95.0);

    return WeatherData(
      temperatureC: double.parse(baseTemp.toStringAsFixed(1)),
      relativeHumidityPct: double.parse(humidity.toStringAsFixed(1)),
      atmosphericPressureHpa: 1012.0,
      uvIndex: (hour >= 10 && hour <= 15) ? 7.8 : 2.1,
      windSpeedMps: 2.8,
      weatherCondition: 'Partly Cloudy',
      weatherDescription: 'scattered clouds with mild humidity',
      iconCode: (hour >= 6 && hour < 18) ? '02d' : '02n',
      cityName: 'Colombo',
      countryCode: 'LK',
      latitude: latitude,
      longitude: longitude,
      sunriseTime: DateTime(now.year, now.month, now.day, 6, 5),
      sunsetTime: DateTime(now.year, now.month, now.day, 18, 15),
      recordedAt: now,
    );
  }
}
