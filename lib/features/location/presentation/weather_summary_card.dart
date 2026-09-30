import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/weather_data.dart';
import 'location_providers.dart';

/// Biophilic glassmorphic card displaying hyper-local ambient weather conditions,
/// atmospheric pressure, UV index, and solar daylight duration.
class WeatherSummaryCard extends ConsumerWidget {
  const WeatherSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherDataProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: weatherAsync.when(
        data: (weather) => _buildWeatherContent(context, ref, weather, isDark),
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 32.0),
            child: CircularProgressIndicator(color: AppColors.mintAccent),
          ),
        ),
        error: (error, _) => _buildErrorContent(context, ref, error.toString()),
      ),
    );
  }

  Widget _buildWeatherContent(
    BuildContext context,
    WidgetRef ref,
    WeatherData weather,
    bool isDark,
  ) {
    final primaryTextColor = isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary;
    final secondaryTextColor = isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Location Title & Refresh Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: AppColors.mintAccent,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  '${weather.cityName}, ${weather.countryCode}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                      ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primarySage.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${weather.latitude.toStringAsFixed(2)}°, ${weather.longitude.toStringAsFixed(2)}°',
                    style: TextStyle(
                      fontSize: 11,
                      color: secondaryTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            IconButton(
              tooltip: 'Refresh Weather',
              icon: const Icon(Icons.refresh, size: 20),
              color: AppColors.mintAccent,
              onPressed: () {
                ref.invalidate(weatherDataProvider);
              },
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Primary Temperature & Condition Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${weather.temperatureC.toStringAsFixed(1)}°',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: primaryTextColor,
                        height: 1.0,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 4.0),
                      child: Text(
                        'C',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.mintAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  weather.weatherDescription.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),

            // Weather Condition Badge Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primarySage.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getWeatherIcon(weather.weatherCondition),
                size: 38,
                color: AppColors.mintAccent,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),
        const Divider(height: 1),
        const SizedBox(height: 16),

        // Atmospheric Metrics Grid
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                icon: Icons.water_drop_outlined,
                label: 'Humidity',
                value: '${weather.relativeHumidityPct.toStringAsFixed(0)}%',
                isDark: isDark,
              ),
            ),
            Expanded(
              child: _buildMetricTile(
                icon: Icons.compress_outlined,
                label: 'Pressure',
                value: '${weather.atmosphericPressureHpa.toStringAsFixed(0)} hPa',
                isDark: isDark,
              ),
            ),
            Expanded(
              child: _buildMetricTile(
                icon: Icons.wb_sunny_outlined,
                label: 'UV Index',
                value: weather.uvIndex.toStringAsFixed(1),
                isDark: isDark,
              ),
            ),
            Expanded(
              child: _buildMetricTile(
                icon: Icons.air,
                label: 'Wind',
                value: '${weather.windSpeedMps.toStringAsFixed(1)} m/s',
                isDark: isDark,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Solar Daylight Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.wb_twilight, color: Color(0xFFF4A261), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Sunrise: ${_formatTime(weather.sunriseTime)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.nightlight_round, color: Color(0xFF457B9D), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Sunset: ${_formatTime(weather.sunsetTime)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    final primaryTextColor = isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary;
    final secondaryTextColor = isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary;

    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.mintAccent),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: primaryTextColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: secondaryTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorContent(BuildContext context, WidgetRef ref, String error) {
    return Column(
      children: [
        const Icon(Icons.cloud_off, color: AppColors.statusWarning, size: 36),
        const SizedBox(height: 8),
        Text(
          'Unable to acquire live weather',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          error,
          style: const TextStyle(fontSize: 11, color: AppColors.textDarkSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => ref.invalidate(weatherDataProvider),
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Retry Connection'),
        ),
      ],
    );
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'rain':
      case 'drizzle':
        return Icons.grain;
      case 'thunderstorm':
        return Icons.flash_on;
      default:
        return Icons.wb_cloudy;
    }
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
