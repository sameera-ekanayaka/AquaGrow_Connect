import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/interfaces/i_weather_service.dart';
import '../../../core/models/hydro_supplier.dart';
import '../../../core/models/vpd_reading.dart';
import '../../../core/models/weather_data.dart';
import '../../../core/services/geo_service.dart';
import '../../../core/services/vpd_calculator.dart';
import '../../../core/services/weather_service.dart';

/// Provider for the hardware GPS and geolocation service.
final geoServiceProvider = Provider<GeoService>((ref) {
  return GeoService();
});

/// Provider for the atmospheric weather service.
final weatherServiceProvider = Provider<IWeatherService>((ref) {
  return WeatherService();
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

/// Ambient temperature override for VPD calculations (e.g. from telemetry or user adjustment).
final ambientTempProvider = StateProvider<double>((ref) => 28.5);

/// Ambient humidity override for VPD calculations (e.g. from telemetry or user adjustment).
final ambientHumidityProvider = StateProvider<double>((ref) => 72.0);

/// Real-time Vapor Pressure Deficit (VPD) reading provider.
final vpdReadingProvider = Provider<VpdReading>((ref) {
  final temp = ref.watch(ambientTempProvider);
  final humidity = ref.watch(ambientHumidityProvider);
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
  final searchQuery = ref.watch(supplierSearchQueryProvider).toLowerCase().trim();
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
      final productMatches = s.featuredProducts.any((p) => p.toLowerCase().contains(searchQuery));
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
