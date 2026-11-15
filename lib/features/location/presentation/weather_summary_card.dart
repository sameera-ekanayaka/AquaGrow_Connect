import 'package:aquagrow_mobile/core/logging/app_logger.dart';
import 'package:aquagrow_mobile/core/models/weather_data.dart';
import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/features/location/domain/location_access_status.dart';
import 'package:aquagrow_mobile/features/location/presentation/location_providers.dart';
import 'package:aquagrow_mobile/features/location/presentation/widgets/location_status_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Card displaying hyper-local ambient weather conditions,
/// atmospheric pressure, UV index, and solar daylight schedule.
///
/// Restyled strictly to Figma design tokens (`context.ag`, `AgSpace`, `AgRadius`).
/// Displays a [LocationStatusBanner] whenever GPS or permission is degraded.
class WeatherSummaryCard extends ConsumerWidget {
  static const _logger = AppLogger('weather');

  /// Creates a [WeatherSummaryCard].
  const WeatherSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherDataProvider);
    final locationResultAsync = ref.watch(locationResultProvider);
    final colors = context.ag;

    return Container(
      padding: const EdgeInsets.all(AgSpace.s16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AgRadius.all(AgRadius.r20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location permission status banner (hidden when GPS granted)
          locationResultAsync.when(
            data: (result) => LocationStatusBanner(result: result),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => LocationStatusBanner(
              result: LocationResult.serviceDisabled(),
            ),
          ),

          // Weather content
          weatherAsync.when(
            data: (weather) => _buildWeatherContent(context, ref, weather),
            loading: () => Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AgSpace.s32),
                child: CircularProgressIndicator(color: colors.brand),
              ),
            ),
            error: (error, stackTrace) {
              _logger.warning('Failed to load weather: $error', error);
              return _buildErrorContent(context, ref);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherContent(
    BuildContext context,
    WidgetRef ref,
    WeatherData weather,
  ) {
    final colors = context.ag;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Location Title & Refresh Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: colors.brand,
                    size: 20,
                  ),
                  const SizedBox(width: AgSpace.s8),
                  Flexible(
                    child: Text(
                      '${weather.cityName}, ${weather.countryCode}',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.text,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AgSpace.s8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.brandSurface,
                      borderRadius: AgRadius.all(AgRadius.pill),
                    ),
                    child: Text(
                      '${weather.latitude.toStringAsFixed(2)}°, ${weather.longitude.toStringAsFixed(2)}°',
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Refresh Weather',
              icon: Icon(Icons.refresh, size: 18, color: colors.textSecondary),
              onPressed: () => ref.invalidate(weatherDataProvider),
            ),
          ],
        ),

        const SizedBox(height: AgSpace.s12),

        // Primary Temperature & Condition Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${weather.temperatureC.toStringAsFixed(1)}°',
                        style: textTheme.displayMedium?.copyWith(
                          color: colors.text,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: AgSpace.s4),
                        child: Text(
                          'C',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AgSpace.s4),
                  Text(
                    weather.weatherDescription.toUpperCase(),
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1,
                      color: colors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AgSpace.s8),

            // Weather Condition Badge Icon
            Container(
              padding: const EdgeInsets.all(AgSpace.s12),
              decoration: BoxDecoration(
                color: colors.brandSurface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getWeatherIcon(weather.weatherCondition),
                size: 32,
                color: colors.text,
              ),
            ),
          ],
        ),

        const SizedBox(height: AgSpace.s16),
        Divider(color: colors.border, height: 1),
        const SizedBox(height: AgSpace.s16),

        // Atmospheric Metrics Grid
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                context: context,
                icon: Icons.water_drop_outlined,
                label: 'Humidity',
                value: '${weather.relativeHumidityPct.toStringAsFixed(0)}%',
              ),
            ),
            Expanded(
              child: _buildMetricTile(
                context: context,
                icon: Icons.compress_outlined,
                label: 'Pressure',
                value:
                    '${weather.atmosphericPressureHpa.toStringAsFixed(0)} hPa',
              ),
            ),
            Expanded(
              child: _buildMetricTile(
                context: context,
                icon: Icons.wb_sunny_outlined,
                label: 'UV Index',
                value: weather.uvIndex.toStringAsFixed(1),
              ),
            ),
            Expanded(
              child: _buildMetricTile(
                context: context,
                icon: Icons.air,
                label: 'Wind',
                value: '${weather.windSpeedMps.toStringAsFixed(1)} m/s',
              ),
            ),
          ],
        ),

        const SizedBox(height: AgSpace.s16),

        // Solar Daylight Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: colors.subtle,
            borderRadius: AgRadius.all(AgRadius.r16),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.wb_twilight, color: colors.warning, size: 18),
                    const SizedBox(width: AgSpace.s8),
                    Flexible(
                      child: Text(
                        'Sunrise: ${_formatTime(weather.sunriseTime)}',
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AgSpace.s8),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.nightlight_round,
                      color: colors.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: AgSpace.s8),
                    Flexible(
                      child: Text(
                        'Sunset: ${_formatTime(weather.sunsetTime)}',
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    final colors = context.ag;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Icon(icon, size: 18, color: colors.brand),
        const SizedBox(height: AgSpace.s4),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.text,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorContent(BuildContext context, WidgetRef ref) {
    final colors = context.ag;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Icon(Icons.cloud_off, color: colors.warning, size: 36),
        const SizedBox(height: AgSpace.s8),
        Text(
          'Unable to acquire live weather',
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.text,
          ),
        ),
        const SizedBox(height: AgSpace.s4),
        Text(
          'Could not load the weather. Check your connection.',
          style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AgSpace.s12),
        OutlinedButton.icon(
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
