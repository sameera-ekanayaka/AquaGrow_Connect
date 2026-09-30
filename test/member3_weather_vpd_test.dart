import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aquagrow_mobile/core/interfaces/i_weather_service.dart';
import 'package:aquagrow_mobile/core/mocks/mock_weather_service.dart';
import 'package:aquagrow_mobile/core/models/hydro_supplier.dart';
import 'package:aquagrow_mobile/core/models/vpd_reading.dart';
import 'package:aquagrow_mobile/core/models/weather_data.dart';
import 'package:aquagrow_mobile/core/services/geo_service.dart';
import 'package:aquagrow_mobile/core/services/vpd_calculator.dart';
import 'package:aquagrow_mobile/core/services/weather_service.dart';
import 'package:aquagrow_mobile/features/location/presentation/location_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Member 3: Tetens Equation & Psychrometric Science Tests', () {
    test('Calculates Saturation Vapor Pressure according to standard psychrometric tables', () {
      // Reference standard: At 25°C, saturation vapor pressure of pure water is ~3.167 kPa
      final double vpSat25 = VpdCalculator.calculateSaturationVaporPressure(25.0);
      expect(vpSat25, closeTo(3.167, 0.05));

      // Reference standard: At 30°C, saturation vapor pressure is ~4.24 kPa
      final double vpSat30 = VpdCalculator.calculateSaturationVaporPressure(30.0);
      expect(vpSat30, closeTo(4.24, 0.05));

      // Reference standard: At 20°C, saturation vapor pressure is ~2.34 kPa
      final double vpSat20 = VpdCalculator.calculateSaturationVaporPressure(20.0);
      expect(vpSat20, closeTo(2.34, 0.05));
    });

    test('Calculates Actual Vapor Pressure accurately based on Relative Humidity', () {
      // At 25°C and 50% RH: Actual VP should be exactly 50% of saturation VP
      final double vpSat = VpdCalculator.calculateSaturationVaporPressure(25.0);
      final double vpAct = VpdCalculator.calculateActualVaporPressure(25.0, 50.0);

      expect(vpAct, closeTo(vpSat * 0.5, 0.001));
    });

    test('Clamps humidity strictly between 0% and 100%', () {
      final double vpActOver = VpdCalculator.calculateActualVaporPressure(25.0, 150.0);
      final double vpSat = VpdCalculator.calculateSaturationVaporPressure(25.0);
      expect(vpActOver, closeTo(vpSat, 0.001));

      final double vpActNegative = VpdCalculator.calculateActualVaporPressure(25.0, -20.0);
      expect(vpActNegative, closeTo(0.0, 0.001));
    });
  });

  group('Member 3: VPD Physiological Zone & Horticultural Action Tests', () {
    test('Identifies Under-Transpiration / High Fungal Risk condition (< 0.40 kPa)', () {
      // 25°C with 95% relative humidity creates saturated air with minimal drying power
      final VpdReading reading = VpdCalculator.calculateVpd(
        airTempC: 25.0,
        humidityPct: 95.0,
      );

      expect(reading.vpdKpa, lessThan(0.40));
      expect(reading.zone, equals(VpdZone.underTranspiration));
      expect(reading.isOptimal, isFalse);
      expect(reading.actionableAdvice, contains('ventilation'));
    });

    test('Identifies Early Vegetative / Seedling zone (0.40 - 0.80 kPa)', () {
      final VpdReading reading = VpdCalculator.calculateVpd(
        airTempC: 24.0,
        humidityPct: 75.0,
      );

      expect(reading.vpdKpa, greaterThanOrEqualTo(0.35));
      expect(reading.vpdKpa, lessThan(0.80));
      expect(reading.zone, equals(VpdZone.earlyVegetative));
      expect(reading.isOptimal, isTrue);
    });

    test('Identifies Ideal Vegetative Transpiration zone (0.80 - 1.20 kPa) for leafy greens', () {
      final VpdReading reading = VpdCalculator.calculateVpd(
        airTempC: 27.0,
        humidityPct: 65.0,
      );

      expect(reading.vpdKpa, greaterThanOrEqualTo(0.80));
      expect(reading.vpdKpa, lessThanOrEqualTo(1.20));
      expect(reading.zone, equals(VpdZone.optimalVegetative));
      expect(reading.isOptimal, isTrue);
      expect(reading.statusTitle, contains('Ideal Vegetative'));
    });

    test('Identifies Ideal Generative / Flowering zone (1.20 - 1.60 kPa)', () {
      final VpdReading reading = VpdCalculator.calculateVpd(
        airTempC: 28.0,
        humidityPct: 52.0,
      );

      expect(reading.vpdKpa, greaterThan(1.20));
      expect(reading.vpdKpa, lessThanOrEqualTo(1.60));
      expect(reading.zone, equals(VpdZone.optimalGenerative));
      expect(reading.isOptimal, isTrue);
    });

    test('Identifies High Transpiration Stress / Dehydration zone (> 1.60 kPa)', () {
      // Hot and dry air: 35°C with 30% RH
      final VpdReading reading = VpdCalculator.calculateVpd(
        airTempC: 35.0,
        humidityPct: 30.0,
      );

      expect(reading.vpdKpa, greaterThan(1.60));
      expect(reading.zone, equals(VpdZone.overTranspirationStress));
      expect(reading.isOptimal, isFalse);
      expect(reading.actionableAdvice, contains('grow-light'));
    });
  });

  group('Member 3: Circadian Photoperiod & Solar Automation Tests', () {
    test('Calculates supplemental grow-light hours and symmetric pre-dawn/post-dusk schedule', () {
      final sunrise = DateTime(2026, 10, 1, 6, 0); // 06:00
      final sunset = DateTime(2026, 10, 1, 18, 0);  // 18:00
      // 12.0 hours natural daylight, target is 14.0 hours => 2.0 hours supplement required
      final schedule = VpdCalculator.calculatePhotoperiodSchedule(
        sunrise: sunrise,
        sunset: sunset,
        targetTotalLightHours: 14.0,
      );

      expect(schedule.naturalDaylightHours, equals(12.0));
      expect(schedule.supplementalHoursNeeded, equals(2.0));
      // Pre-dawn LED ON: 1 hour before 06:00 => 05:00
      expect(schedule.growLightOnTime.hour, equals(5));
      expect(schedule.growLightOnTime.minute, equals(0));
      // Post-dusk LED OFF: 1 hour after 18:00 => 19:00
      expect(schedule.growLightOffTime.hour, equals(19));
      expect(schedule.growLightOffTime.minute, equals(0));
      // Solar noon: 12:00
      expect(schedule.solarNoon.hour, equals(12));
    });

    test('Handles natural daylight exceeding target hours without negative supplement', () {
      final sunrise = DateTime(2026, 10, 1, 5, 30);
      final sunset = DateTime(2026, 10, 1, 18, 30); // 13.0 hours daylight
      final schedule = VpdCalculator.calculatePhotoperiodSchedule(
        sunrise: sunrise,
        sunset: sunset,
        targetTotalLightHours: 12.0, // Target is smaller than natural
      );

      expect(schedule.supplementalHoursNeeded, equals(0.0));
      expect(schedule.growLightOnTime, equals(sunrise));
      expect(schedule.growLightOffTime, equals(sunset));
    });
  });

  group('Member 3: Weather Service & JSON Serialization Tests', () {
    test('Parses standard OpenWeatherMap 2.5 JSON response correctly', () {
      final sampleOwmJson = {
        'coord': {'lon': 79.8612, 'lat': 6.9271},
        'weather': [
          {'id': 801, 'main': 'Clouds', 'description': 'few clouds', 'icon': '02d'}
        ],
        'main': {
          'temp': 29.8,
          'pressure': 1012,
          'humidity': 74,
        },
        'wind': {'speed': 4.1},
        'sys': {
          'country': 'LK',
          'sunrise': 1727656800,
          'sunset': 1727700000,
        },
        'dt': 1727678400,
        'name': 'Colombo',
      };

      final WeatherData weather = WeatherData.fromOpenWeatherMapJson(sampleOwmJson);

      expect(weather.cityName, equals('Colombo'));
      expect(weather.countryCode, equals('LK'));
      expect(weather.temperatureC, equals(29.8));
      expect(weather.relativeHumidityPct, equals(74.0));
      expect(weather.atmosphericPressureHpa, equals(1012.0));
      expect(weather.windSpeedMps, equals(4.1));
      expect(weather.weatherCondition, equals('Clouds'));
      expect(weather.iconCode, equals('02d'));
    });

    test('MockWeatherService executes offline with realistic coordinates and diurnal temperatures', () async {
      final IWeatherService mockService = MockWeatherService(seed: 100);
      final WeatherData weather = await mockService.fetchWeather(
        latitude: 6.9271,
        longitude: 79.8612,
      );

      expect(weather.cityName, equals('Colombo'));
      expect(weather.countryCode, equals('LK'));
      expect(weather.temperatureC, greaterThanOrEqualTo(24.0));
      expect(weather.temperatureC, lessThanOrEqualTo(35.0));
      expect(weather.relativeHumidityPct, greaterThanOrEqualTo(50.0));
      expect(weather.sunriseTime.isBefore(weather.sunsetTime), isTrue);
    });

    test('WeatherService safely delegates to MockWeatherService when API key is null or empty', () async {
      final weatherService = WeatherService(defaultApiKey: null);
      final weather = await weatherService.fetchWeather(
        latitude: 7.2906,
        longitude: 80.6337,
      );

      expect(weather.cityName, equals('Kandy'));
      expect(weather.temperatureC, isNotNull);
    });
  });

  group('Member 3: GPS Geolocation & Haversine Distance Tests', () {
    test('GeoService falls back to default Colombo position without crashing', () async {
      final geoService = GeoService();
      final position = await geoService.getCurrentPosition();

      expect(position.latitude, equals(6.9271));
      expect(position.longitude, equals(79.8612));
      expect(position.isSimulated, isTrue);
    });

    test('GeoService accepts injected mock coordinates for deterministic testing', () async {
      final geoService = GeoService();
      geoService.setMockLocation(GeoPosition.defaultKandy);

      final position = await geoService.getCurrentPosition();
      expect(position.latitude, equals(7.2906));
      expect(position.longitude, equals(80.6337));
      expect(position.locationSource, contains('Kandy'));
    });

    test('Calculates Haversine distance between Colombo and Kandy accurately (~95-115 km)', () {
      final geoService = GeoService();
      final double distanceKm = geoService.distanceBetween(
        startLatitude: 6.9271,
        startLongitude: 79.8612,
        endLatitude: 7.2906,
        endLongitude: 80.6337,
      );

      expect(distanceKm, closeTo(95.0, 15.0));
    });

    test('HydroSupplier computes correct distance from user coordinates', () {
      final supplier = HydroSupplier.defaultSuppliers.first; // Nugegoda supplier
      // User at Colombo Fort (6.9350, 79.8450) to Nugegoda (6.8710, 79.8970)
      final double dist = supplier.distanceInKmFrom(6.9350, 79.8450);

      expect(dist, greaterThan(6.0));
      expect(dist, lessThan(15.0));
    });
  });

  group('Member 3: Riverpod State Providers & Supplier Filtering Tests', () {
    test('VPD provider reacts dynamically to ambient temperature and humidity state updates', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Initial state
      final initialVpd = container.read(vpdReadingProvider);
      expect(initialVpd.airTemperatureC, equals(28.5));
      expect(initialVpd.relativeHumidityPct, equals(72.0));

      // Simulate extreme heat and dryness
      container.read(ambientTempProvider.notifier).state = 36.0;
      container.read(ambientHumidityProvider.notifier).state = 25.0;

      final stressedVpd = container.read(vpdReadingProvider);
      expect(stressedVpd.airTemperatureC, equals(36.0));
      expect(stressedVpd.zone, equals(VpdZone.overTranspirationStress));
      expect(stressedVpd.isOptimal, isFalse);
    });

    test('Filters suppliers by category and sorts by proximity', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Default: All categories
      final allSuppliers = container.read(sortedSuppliersProvider);
      expect(allSuppliers.length, equals(HydroSupplier.defaultSuppliers.length));

      // Filter by Nutrients & Buffers
      container.read(selectedSupplierCategoryProvider.notifier).state = 'Nutrients & Buffers';
      final nutrientSuppliers = container.read(sortedSuppliersProvider);

      expect(nutrientSuppliers.length, equals(1));
      expect(nutrientSuppliers.first.category, equals('Nutrients & Buffers'));
      expect(nutrientSuppliers.first.name, equals('Lanka Hydroponics Hub'));

      // Search by keyword 'rockwool'
      container.read(selectedSupplierCategoryProvider.notifier).state = 'All';
      container.read(supplierSearchQueryProvider.notifier).state = 'rockwool';
      final rockwoolSuppliers = container.read(sortedSuppliersProvider);

      expect(rockwoolSuppliers.isNotEmpty, isTrue);
      expect(rockwoolSuppliers.first.featuredProducts.any((p) => p.toLowerCase().contains('rockwool')), isTrue);
    });
  });
}
