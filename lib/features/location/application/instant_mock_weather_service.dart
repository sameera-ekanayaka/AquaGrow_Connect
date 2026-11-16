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
      cityName: _resolveCity(latitude, longitude),
      countryCode: 'LK',
      latitude: latitude,
      longitude: longitude,
      sunriseTime: DateTime(now.year, now.month, now.day, 6, 5),
      sunsetTime: DateTime(now.year, now.month, now.day, 18, 15),
      recordedAt: now,
    );
  }

  String _resolveCity(double lat, double lon) {
    if ((lat - 6.9271).abs() < 0.12 && (lon - 79.8612).abs() < 0.12) {
      return 'Colombo';
    }
    if ((lat - 7.0840).abs() < 0.12 && (lon - 79.9926).abs() < 0.12) {
      return 'Gampaha';
    }
    if ((lat - 6.5854).abs() < 0.15 && (lon - 79.9607).abs() < 0.15) {
      return 'Kalutara';
    }
    if ((lat - 7.2906).abs() < 0.15 && (lon - 80.6337).abs() < 0.15) {
      return 'Kandy';
    }
    if ((lat - 6.0535).abs() < 0.15 && (lon - 80.2210).abs() < 0.15) {
      return 'Galle';
    }
    if ((lat - 5.9549).abs() < 0.15 && (lon - 80.5550).abs() < 0.15) {
      return 'Matara';
    }
    if ((lat - 7.4863).abs() < 0.15 && (lon - 80.3623).abs() < 0.15) {
      return 'Kurunegala';
    }
    if ((lat - 7.2088).abs() < 0.15 && (lon - 79.8358).abs() < 0.15) {
      return 'Negombo';
    }
    if ((lat - 8.3114).abs() < 0.25 && (lon - 80.4037).abs() < 0.25) {
      return 'Anuradhapura';
    }
    if ((lat - 9.6615).abs() < 0.25 && (lon - 80.0074).abs() < 0.25) {
      return 'Jaffna';
    }
    if ((lat - 6.9497).abs() < 0.20 && (lon - 80.7891).abs() < 0.20) {
      return 'Nuwara Eliya';
    }
    if ((lat - 6.6828).abs() < 0.15 && (lon - 80.4036).abs() < 0.15) {
      return 'Ratnapura';
    }
    if ((lat - 6.9271).abs() > 0.05 || (lon - 79.8612).abs() > 0.05) {
      return '${lat.toStringAsFixed(2)}°, ${lon.toStringAsFixed(2)}°';
    }
    return 'Colombo';
  }
}
