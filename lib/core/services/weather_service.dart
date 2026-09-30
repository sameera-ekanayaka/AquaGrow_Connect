import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../interfaces/i_weather_service.dart';
import '../mocks/mock_weather_service.dart';
import '../models/weather_data.dart';

/// Real OpenWeatherMap REST API client with automatic fallback to [MockWeatherService].
/// Guarantees that whether an API key is available or offline, the app continues
/// functioning with zero disruptions.
class WeatherService implements IWeatherService {
  final http.Client _client;
  final MockWeatherService _mockFallback;
  final String? _defaultApiKey;

  WeatherService({
    http.Client? client,
    MockWeatherService? mockFallback,
    String? defaultApiKey,
  })  : _client = client ?? http.Client(),
        _mockFallback = mockFallback ?? MockWeatherService(),
        _defaultApiKey = defaultApiKey;

  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  @override
  Future<WeatherData> fetchWeather({
    required double latitude,
    required double longitude,
    String? apiKey,
  }) async {
    final key = apiKey ?? _defaultApiKey;

    // If no API key is provided, transparently utilize realistic mock weather
    if (key == null || key.trim().isEmpty) {
      debugPrint('[WeatherService] No OpenWeatherMap API key provided. Utilizing MockWeatherService.');
      return _mockFallback.fetchWeather(latitude: latitude, longitude: longitude);
    }

    try {
      final uri = Uri.parse('$_baseUrl?lat=$latitude&lon=$longitude&units=metric&appid=$key');
      final response = await _client.get(uri).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
        return WeatherData.fromOpenWeatherMapJson(data);
      } else {
        debugPrint('[WeatherService] OpenWeatherMap returned HTTP ${response.statusCode}: ${response.body}. Using fallback.');
        return _mockFallback.fetchWeather(latitude: latitude, longitude: longitude);
      }
    } catch (e) {
      debugPrint('[WeatherService] Network or decoding error: $e. Using fallback.');
      return _mockFallback.fetchWeather(latitude: latitude, longitude: longitude);
    }
  }

  @override
  Future<WeatherData> fetchWeatherByCity({
    required String cityName,
    String? apiKey,
  }) async {
    final key = apiKey ?? _defaultApiKey;

    if (key == null || key.trim().isEmpty) {
      debugPrint('[WeatherService] No API key provided for city query. Utilizing MockWeatherService.');
      return _mockFallback.fetchWeatherByCity(cityName: cityName);
    }

    try {
      final uri = Uri.parse('$_baseUrl?q=$cityName&units=metric&appid=$key');
      final response = await _client.get(uri).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
        return WeatherData.fromOpenWeatherMapJson(data);
      } else {
        debugPrint('[WeatherService] HTTP ${response.statusCode} for $cityName. Using fallback.');
        return _mockFallback.fetchWeatherByCity(cityName: cityName);
      }
    } catch (e) {
      debugPrint('[WeatherService] Network error for city $cityName: $e. Using fallback.');
      return _mockFallback.fetchWeatherByCity(cityName: cityName);
    }
  }
}
