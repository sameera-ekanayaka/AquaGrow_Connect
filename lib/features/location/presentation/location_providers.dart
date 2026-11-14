import 'dart:math' as math;

import 'package:aquagrow_mobile/core/config/app_config.dart';
import 'package:aquagrow_mobile/core/interfaces/i_weather_service.dart';
import 'package:aquagrow_mobile/core/mocks/mock_weather_service.dart';
import 'package:aquagrow_mobile/core/models/hydro_supplier.dart';
import 'package:aquagrow_mobile/core/models/vpd_reading.dart';
import 'package:aquagrow_mobile/core/models/weather_data.dart';
import 'package:aquagrow_mobile/core/services/geo_service.dart';
import 'package:aquagrow_mobile/core/services/vpd_calculator.dart';
import 'package:aquagrow_mobile/core/services/weather_service.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Provider for the hardware GPS and geolocation service.
final geoServiceProvider = Provider<GeoService>((ref) {
  return GeoService();
});

/// Provider for the atmospheric weather service.
///
/// Automatically uses the API key configured in [AppConfig], delegating to
/// [InstantMockWeatherService] when offline or no API key is set.
final weatherServiceProvider = Provider<IWeatherService>((ref) {
  final config = ref.watch(appConfigProvider);
  if (!config.hasWeatherKey) {
    return InstantMockWeatherService();
  }
  return WeatherService(defaultApiKey: config.openWeatherApiKey);
});

/// Current geographic coordinates provider with asynchronous acquisition.
final currentPositionProvider = FutureProvider<GeoPosition>((ref) async {
  final geoService = ref.watch(geoServiceProvider);
  return await geoService.getCurrentPosition();
});

/// Live outdoor atmospheric weather data provider based on current GPS location.
final weatherDataProvider = FutureProvider<WeatherData>((ref) async {
  final positionAsync = ref.watch(currentPositionProvider);
  final weatherService = ref.watch(weatherServiceProvider);

  final position = positionAsync.value ?? GeoPosition.defaultColombo;
  return await weatherService.fetchWeather(
    latitude: position.latitude,
    longitude: position.longitude,
  );
});

/// Target daily light hours (defaulting to 14.0 hours for vegetative hydroponics).
final targetLightHoursProvider = StateProvider<double>((ref) => 14.0);

/// Circadian photoperiod schedule provider.
final photoperiodScheduleProvider = Provider<PhotoperiodSchedule?>((ref) {
  final weatherAsync = ref.watch(weatherDataProvider);
  final targetHours = ref.watch(targetLightHoursProvider);

  return weatherAsync.when(
    data: (weather) => VpdCalculator.calculatePhotoperiodSchedule(
      sunrise: weather.sunriseTime,
      sunset: weather.sunsetTime,
      targetTotalLightHours: targetHours,
    ),
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Ambient temperature fallback for VPD calculations when sensor readings lack ambient temp.
final ambientTempProvider = StateProvider<double>((ref) => 28.5);

/// Ambient humidity fallback for VPD calculations when sensor readings lack ambient humidity.
final ambientHumidityProvider = StateProvider<double>((ref) => 72.0);

/// Real-time Vapor Pressure Deficit (VPD) reading provider.
///
/// Automatically feeds from the selected pod's latest [SensorReading.ambientTempC]
/// and [SensorReading.humidityPct] via [latestReadingProvider], falling back to
/// manual ambient settings if not yet reporting.
final vpdReadingProvider = Provider<VpdReading>((ref) {
  final selectedPodId = ref.watch(selectedPodIdProvider);
  final latestReading =
      ref.watch(latestReadingProvider(selectedPodId)).valueOrNull;

  final double temp =
      latestReading?.ambientTempC ?? ref.watch(ambientTempProvider);
  final double humidity =
      latestReading?.humidityPct ?? ref.watch(ambientHumidityProvider);

  return VpdCalculator.calculateVpd(
    airTempC: temp,
    humidityPct: humidity,
  );
});

/// Selected filter category for hydroponic supplier directory.
final selectedSupplierCategoryProvider = StateProvider<String>((ref) => 'All');

/// Search query string for hydroponic supplier directory.
final supplierSearchQueryProvider = StateProvider<String>((ref) => '');

/// Filtered and distance-sorted list of verified hydroponic suppliers.
final sortedSuppliersProvider = Provider<List<HydroSupplier>>((ref) {
  final selectedCategory = ref.watch(selectedSupplierCategoryProvider);
  final searchQuery =
      ref.watch(supplierSearchQueryProvider).toLowerCase().trim();
  final positionAsync = ref.watch(currentPositionProvider);
  final position = positionAsync.value ?? GeoPosition.defaultColombo;

  var suppliers = List<HydroSupplier>.from(HydroSupplier.defaultSuppliers);

  // Filter by category
  if (selectedCategory != 'All') {
    suppliers = suppliers.where((s) => s.category == selectedCategory).toList();
  }

  // Filter by search query (name, city, address, or products)
  if (searchQuery.isNotEmpty) {
    suppliers = suppliers.where((s) {
      final nameMatches = s.name.toLowerCase().contains(searchQuery);
      final cityMatches = s.city.toLowerCase().contains(searchQuery);
      final productMatches =
          s.featuredProducts.any((p) => p.toLowerCase().contains(searchQuery));
      return nameMatches || cityMatches || productMatches;
    }).toList();
  }

  // Sort by distance ascending from user location
  suppliers.sort((a, b) {
    final distA = a.distanceInKmFrom(position.latitude, position.longitude);
    final distB = b.distanceInKmFrom(position.latitude, position.longitude);
    return distA.compareTo(distB);
  });

  return suppliers;
});
