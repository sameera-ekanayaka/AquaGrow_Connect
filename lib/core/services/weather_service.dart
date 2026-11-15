import 'dart:convert';

import 'package:aquagrow_mobile/core/interfaces/i_weather_service.dart';
import 'package:aquagrow_mobile/core/logging/app_logger.dart';
import 'package:aquagrow_mobile/core/mocks/mock_weather_service.dart';
import 'package:aquagrow_mobile/core/models/weather_data.dart';
import 'package:http/http.dart' as http;

/// Real OpenWeatherMap REST client with automatic fallback to [MockWeatherService].
///
/// Whether an API key is missing, the network is down or the server fails,
/// the app keeps working with mock weather. Errors are never logged in full
/// because the request address contains the API key.
class WeatherService implements IWeatherService {
  /// Creates the service. Pass [client] and [mockFallback] in tests.
  WeatherService({
    http.Client? client,
    MockWeatherService? mockFallback,
    String? defaultApiKey,
  })  : _client = client ?? http.Client(),
        _mockFallback = mockFallback ?? MockWeatherService(),
        _defaultApiKey = defaultApiKey;

  static const _log = AppLogger('weather');
  static const String _host = 'api.openweathermap.org';
  static const String _path = '/data/2.5/weather';
  static const Duration _timeout = Duration(seconds: 6);

  final http.Client _client;
  final MockWeatherService _mockFallback;
  final String? _defaultApiKey;

  @override
  Future<WeatherData> fetchWeather({
    required double latitude,
    required double longitude,
    String? apiKey,
  }) async {
    final key = apiKey ?? _defaultApiKey;
    if (key == null || key.trim().isEmpty) {
      _log.info('No OpenWeatherMap key. Using mock weather.');
      return _mockFallback.fetchWeather(
        latitude: latitude,
        longitude: longitude,
      );
    }

    final live = await _request({'lat': '$latitude', 'lon': '$longitude'}, key);
    return live ??
        _mockFallback.fetchWeather(
          latitude: latitude,
          longitude: longitude,
        );
  }

  @override
  Future<WeatherData> fetchWeatherByCity({
    required String cityName,
    String? apiKey,
  }) async {
    final key = apiKey ?? _defaultApiKey;
    if (key == null || key.trim().isEmpty) {
      _log.info('No OpenWeatherMap key. Using mock weather.');
      return _mockFallback.fetchWeatherByCity(cityName: cityName);
    }

    final live = await _request({'q': cityName}, key);
    return live ?? _mockFallback.fetchWeatherByCity(cityName: cityName);
  }

  /// Calls the API and returns the parsed weather, or `null` on any failure.
  Future<WeatherData?> _request(Map<String, String> query, String key) async {
    try {
      final uri = Uri.https(_host, _path, {
        ...query,
        'units': 'metric',
        'appid': key,
      });
      final response = await _client.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return WeatherData.fromOpenWeatherMapJson(data);
      }
      _log.warning(
        'OpenWeatherMap returned HTTP ${response.statusCode}. Using fallback.',
      );
    } catch (_) {
      // The error object can contain the request address and the key.
      _log.warning('Weather request failed. Using fallback.');
    }
    return null;
  }
}
