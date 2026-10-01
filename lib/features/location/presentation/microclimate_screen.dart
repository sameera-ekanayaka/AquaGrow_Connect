import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import 'hydro_map_screen.dart';
import 'location_providers.dart';
import 'vpd_gauge_card.dart';
import 'weather_summary_card.dart';

/// Master command center for Member 3: GPS Geolocation & Microclimate Services.
/// Integrates GPS coordinate ingestion, hyper-local OpenWeatherMap telemetry,
/// Vapor Pressure Deficit (VPD) transpiration diagnostics, and circadian photoperiod automation.
class MicroclimateScreen extends ConsumerWidget {
  const MicroclimateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary;
    final secondaryTextColor = isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary;
    final photoperiod = ref.watch(photoperiodScheduleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Microclimate & Location'),
        actions: [
          IconButton(
            tooltip: 'Open Hydro-Hub Suppliers',
            icon: const Icon(Icons.storefront_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HydroMapScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.mintAccent,
        onRefresh: () async {
          ref.invalidate(currentPositionProvider);
          ref.invalidate(weatherDataProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Hyper-Local Weather Card
              const WeatherSummaryCard(),

              // 2. Real-Time Vapor Pressure Deficit (VPD) Advisor
              const VpdGaugeCard(),

              // 3. Circadian Photoperiod & Light Sync Card
              if (photoperiod != null)
                _buildPhotoperiodCard(context, ref, photoperiod, isDark, primaryTextColor, secondaryTextColor),

              // 4. Hydro-Hub Supply Directory Banner
              _buildHydroHubBanner(context, isDark, primaryTextColor, secondaryTextColor),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoperiodCard(
    BuildContext context,
    WidgetRef ref,
    dynamic photoperiod,
    bool isDark,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4A261).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.wb_sunny_outlined, color: Color(0xFFF4A261), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Circadian Photoperiod Sync',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: primaryTextColor,
                            ),
                      ),
                      Text(
                        'Solar Curve & LED Scheduling',
                        style: TextStyle(
                          fontSize: 11,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primarySage.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${photoperiod.targetLightHours.toStringAsFixed(0)}h TARGET',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.mintAccent,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Daylight vs Supplement Metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.light_mode,
                  label: 'Natural Daylight',
                  value: '${photoperiod.naturalDaylightHours} hrs',
                  color: const Color(0xFFF4A261),
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                ),
              ),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.bolt,
                  label: 'LED Supplement',
                  value: '${photoperiod.supplementalHoursNeeded} hrs',
                  color: AppColors.mintAccent,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                ),
              ),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.wb_twilight,
                  label: 'Solar Noon',
                  value: _formatTime(photoperiod.solarNoon),
                  color: const Color(0xFF457B9D),
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Smart Automation Timeline
          Text(
            'Recommended Grow-Light Automation Schedule',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: secondaryTextColor),
          ),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildScheduleBadge(
                title: 'LED ON (Pre-Dawn)',
                time: _formatTime(photoperiod.growLightOnTime),
                icon: Icons.timer,
                isDark: isDark,
              ),
              const Icon(Icons.arrow_forward, size: 16, color: AppColors.mintAccent),
              _buildScheduleBadge(
                title: 'LED OFF (Post-Dusk)',
                time: _formatTime(photoperiod.growLightOffTime),
                icon: Icons.nightlight,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return Column(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: primaryTextColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: secondaryTextColor),
        ),
      ],
    );
  }

  Widget _buildScheduleBadge({
    required String title,
    required String time,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.mintAccent),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 10, color: AppColors.textDarkSecondary),
              ),
              Text(
                time,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHydroHubBanner(
    BuildContext context,
    bool isDark,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppColors.forestDepth, AppColors.darkSurfaceElevated]
              : [AppColors.lightMintBackground, AppColors.lightSurfaceElevated],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primarySage.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primarySage.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.map_outlined, color: AppColors.mintAccent, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hydro-Hub Supply Network',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Find verified local retailers for MasterBlend, rockwool, and probes with GPS distance.',
                  style: TextStyle(fontSize: 11, color: secondaryTextColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HydroMapScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: const Text('Explore'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
