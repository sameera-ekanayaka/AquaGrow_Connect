import '../models/weather_data.dart';

/// Abstract contract for atmospheric weather and solar data providers.
/// Enables seamless substitution between live OpenWeatherMap API and offline mocks.
abstract class IWeatherService {
  /// Fetches weather telemetry by geographic coordinates (latitude & longitude).
  Future<WeatherData> fetchWeather({
    required double latitude,
    required double longitude,
    String? apiKey,
  });

  /// Fetches weather telemetry by city name (e.g. 'Colombo', 'Kandy').
  Future<WeatherData> fetchWeatherByCity({
    required String cityName,
    String? apiKey,
  });
}
