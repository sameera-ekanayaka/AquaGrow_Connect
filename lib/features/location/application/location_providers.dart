import 'package:aquagrow_mobile/core/config/app_config.dart';
import 'package:aquagrow_mobile/core/interfaces/i_geo_service.dart';
import 'package:aquagrow_mobile/core/interfaces/i_launcher_service.dart';
import 'package:aquagrow_mobile/core/interfaces/i_weather_service.dart';
import 'package:aquagrow_mobile/core/models/hydro_supplier.dart';
import 'package:aquagrow_mobile/core/models/vpd_reading.dart';
import 'package:aquagrow_mobile/core/models/weather_data.dart';
import 'package:aquagrow_mobile/core/services/geo_service.dart';
import 'package:aquagrow_mobile/core/services/launcher_service.dart';
import 'package:aquagrow_mobile/core/services/vpd_calculator.dart';
import 'package:aquagrow_mobile/core/services/weather_service.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/features/location/application/instant_mock_weather_service.dart';
import 'package:aquagrow_mobile/features/location/domain/location_access_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the hardware GPS and geolocation service.
final geoServiceProvider = Provider<IGeoService>((ref) {
  return GeoService();
});

/// Provider for external action launching (phone dialer, maps directions).
final launcherServiceProvider = Provider<ILauncherService>((ref) {
  return const LauncherService();
});

/// Selected display mode (List or Map) for the hydroponic supplier directory.
enum SupplierViewMode {
  /// Scrollable vertical list view.
  list,

  /// Interactive OpenStreetMap tile view.
  map,
}

/// Tracks the active supplier directory view mode (defaults to [SupplierViewMode.list]).
final supplierViewModeProvider =
    StateProvider<SupplierViewMode>((ref) => SupplierViewMode.list);

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

/// Tracks whether the location rationale dialog has been shown in this session.
final locationRationaleShownProvider = StateProvider<bool>((ref) => false);

/// Key for persisting user location query consent in app preferences.
const String kLocationConsentPrefKey = 'location_consent_granted';

/// Tracks whether the user has given consent to query device GPS location.
/// Initialized from persistent preferences so consent survives app restarts.
final locationConsentProvider = StateProvider<bool>((ref) {
  final prefs = ref.watch(preferencesStoreProvider);
  return prefs.getBool(kLocationConsentPrefKey, fallback: false);
});

/// Asynchronous location acquisition result, including permission status.
///
/// Returns a [LocationResult] that callers can inspect for [LocationResult.isFallback]
/// and [LocationResult.status] to decide what banner or action to present.
final locationResultProvider = FutureProvider<LocationResult>((ref) async {
  final hasConsent = ref.watch(locationConsentProvider);
  if (!hasConsent) {
    return LocationResult.denied(
      reason: 'GPS unavailable, showing Colombo',
    );
  }
  final geoService = ref.watch(geoServiceProvider);
  return await geoService.getPosition();
});

/// Current geographic coordinates provider — extracts [GeoPosition] from [locationResultProvider].
///
/// Falls back to Colombo when permission is denied or GPS unavailable.
final currentPositionProvider = FutureProvider<GeoPosition>((ref) async {
  final result = await ref.watch(locationResultProvider.future);
  return result.position;
});

/// Human-readable fallback note shown in the UI when location could not be acquired.
///
/// Returns `null` when the full GPS location was obtained successfully.
final locationFallbackNoteProvider = Provider<String?>((ref) {
  final resultAsync = ref.watch(locationResultProvider);
  return resultAsync.valueOrNull?.isFallback == true
      ? resultAsync.valueOrNull?.fallbackReason
      : null;
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
