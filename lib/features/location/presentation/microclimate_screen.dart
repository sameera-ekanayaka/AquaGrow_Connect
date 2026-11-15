import 'package:aquagrow_mobile/core/services/vpd_calculator.dart';
import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/features/location/application/location_providers.dart';
import 'package:aquagrow_mobile/features/location/presentation/hydro_map_screen.dart';
import 'package:aquagrow_mobile/features/location/presentation/vpd_gauge_card.dart';
import 'package:aquagrow_mobile/features/location/presentation/weather_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Microclimate and outdoor telemetry screen.
///
/// Integrates GPS coordinate ingestion, hyper-local OpenWeatherMap telemetry,
/// Vapor Pressure Deficit (VPD) transpiration diagnostics, and circadian photoperiod automation.
class MicroclimateScreen extends ConsumerWidget {
  const MicroclimateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.ag;
    final photoperiod = ref.watch(photoperiodScheduleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Microclimate & Location'),
        actions: [
          IconButton(
            tooltip: 'Open Hydroponic Suppliers',
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
        color: colors.brand,
        onRefresh: () async {
          ref.invalidate(currentPositionProvider);
          ref.invalidate(weatherDataProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: AgSpace.s8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Hyper-Local Weather Card
              const WeatherSummaryCard(),

              // 2. Real-Time Vapor Pressure Deficit (VPD) Advisor
              const VpdGaugeCard(),

              // 3. Circadian Photoperiod & Light Sync Card
              if (photoperiod != null)
                _buildPhotoperiodCard(context, ref, photoperiod),

              // 4. Hydroponic Suppliers Directory Banner
              _buildSuppliersBanner(context),

              const SizedBox(height: AgSpace.s24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoperiodCard(
    BuildContext context,
    WidgetRef ref,
    PhotoperiodSchedule photoperiod,
  ) {
    final colors = context.ag;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AgSpace.screen,
        vertical: AgSpace.s8,
      ),
      padding: const EdgeInsets.all(AgSpace.s16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AgRadius.all(AgRadius.r20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AgSpace.s8),
                    decoration: BoxDecoration(
                      color: colors.warningSurface,
                      borderRadius: AgRadius.all(AgRadius.r16),
                    ),
                    child: Icon(
                      Icons.wb_sunny_outlined,
                      color: colors.warning,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AgSpace.s8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Circadian Photoperiod Sync',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.text,
                        ),
                      ),
                      Text(
                        'Solar Curve & LED Scheduling',
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AgSpace.s8,
                  vertical: AgSpace.s4,
                ),
                decoration: BoxDecoration(
                  color: colors.brandSurface,
                  borderRadius: AgRadius.all(AgRadius.pill),
                ),
                child: Text(
                  '${photoperiod.targetLightHours.toStringAsFixed(0)}h TARGET',
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AgSpace.s16),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  context: context,
                  icon: Icons.light_mode,
                  label: 'Natural Daylight',
                  value: '${photoperiod.naturalDaylightHours} hrs',
                  color: colors.warning,
                ),
              ),
              Expanded(
                child: _buildMetricTile(
                  context: context,
                  icon: Icons.bolt,
                  label: 'LED Supplement',
                  value: '${photoperiod.supplementalHoursNeeded} hrs',
                  color: colors.brand,
                ),
              ),
              Expanded(
                child: _buildMetricTile(
                  context: context,
                  icon: Icons.wb_twilight,
                  label: 'Solar Noon',
                  value: _formatTime(photoperiod.solarNoon),
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AgSpace.s16),
          Divider(height: 1, color: colors.border),
          const SizedBox(height: AgSpace.s12),
          Text(
            'Recommended Grow-Light Automation Schedule',
            style: textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AgSpace.s8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildScheduleBadge(
                context: context,
                title: 'LED ON (Pre-Dawn)',
                time: _formatTime(photoperiod.growLightOnTime),
                icon: Icons.timer,
              ),
              Icon(Icons.arrow_forward, size: 16, color: colors.brand),
              _buildScheduleBadge(
                context: context,
                title: 'LED OFF (Post-Dusk)',
                time: _formatTime(photoperiod.growLightOffTime),
                icon: Icons.nightlight,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final colors = context.ag;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(height: AgSpace.s4),
        Text(
          value,
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.text,
          ),
        ),
        const SizedBox(height: AgSpace.s4),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildScheduleBadge({
    required BuildContext context,
    required String title,
    required String time,
    required IconData icon,
  }) {
    final colors = context.ag;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AgSpace.s12,
        vertical: AgSpace.s8,
      ),
      decoration: BoxDecoration(
        color: colors.subtle,
        borderRadius: AgRadius.all(AgRadius.r16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colors.brand),
          const SizedBox(width: AgSpace.s8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.labelSmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              Text(
                time,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.text,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuppliersBanner(BuildContext context) {
    final colors = context.ag;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AgSpace.screen,
        vertical: AgSpace.s8,
      ),
      padding: const EdgeInsets.all(AgSpace.s16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AgRadius.all(AgRadius.r20),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AgSpace.s12),
            decoration: BoxDecoration(
              color: colors.brandSurface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.storefront_outlined,
              color: colors.brand,
              size: 24,
            ),
          ),
          const SizedBox(width: AgSpace.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hydroponic suppliers',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: AgSpace.s4),
                Text(
                  'Find verified local retailers for nutrients, media, and probes with GPS distance.',
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AgSpace.s8),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HydroMapScreen()),
              );
            },
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
