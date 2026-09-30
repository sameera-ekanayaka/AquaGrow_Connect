import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/vpd_reading.dart';
import 'location_providers.dart';

/// Interactive Vapor Pressure Deficit (VPD) gauge card displaying real-time
/// transpiration health, dynamic psychrometric metrics, and actionable horticultural advice.
class VpdGaugeCard extends ConsumerWidget {
  const VpdGaugeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vpd = ref.watch(vpdReadingProvider);
    final ambientTemp = ref.watch(ambientTempProvider);
    final ambientHumidity = ref.watch(ambientHumidityProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryTextColor = isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary;
    final secondaryTextColor = isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary;
    final zoneColor = _getZoneColor(vpd.zone);

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
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: zoneColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.eco, color: zoneColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vapor Pressure Deficit (VPD)',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: primaryTextColor,
                            ),
                      ),
                      Text(
                        'Canopy Transpiration Physics',
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: zoneColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: zoneColor.withOpacity(0.4), width: 1),
                ),
                child: Text(
                  vpd.isOptimal ? 'OPTIMAL' : 'ATTENTION',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: zoneColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Core Gauge Display: kPa Large Value + Psychrometric Breakdown
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                vpd.vpdKpa.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  color: zoneColor,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'kPa',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: secondaryTextColor,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    vpd.statusTitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Leaf Sat: ${vpd.saturationVpKpa} kPa | Air: ${vpd.actualVpKpa} kPa',
                    style: TextStyle(
                      fontSize: 11,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Multi-Segment Visual Gradient Bar
          _buildVpdGradientBar(vpd.vpdKpa, zoneColor),

          const SizedBox(height: 16),

          // Actionable Horticultural Guidance Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: zoneColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: zoneColor.withOpacity(0.25), width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.tips_and_updates_outlined, color: zoneColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    vpd.actionableAdvice,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: primaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Interactive Microclimate Simulation Controls (Viva & Testing Aid)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Interactive Calibration Simulation',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: secondaryTextColor,
                ),
              ),
              TextButton(
                onPressed: () {
                  ref.read(ambientTempProvider.notifier).state = 28.5;
                  ref.read(ambientHumidityProvider.notifier).state = 72.0;
                },
                child: const Text('Reset', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),

          // Temperature Slider Row
          Row(
            children: [
              const SizedBox(
                width: 75,
                child: Text('Temp (°C):', style: TextStyle(fontSize: 11)),
              ),
              Expanded(
                child: Slider(
                  value: ambientTemp,
                  min: 15.0,
                  max: 42.0,
                  divisions: 54,
                  activeColor: AppColors.mintAccent,
                  label: '${ambientTemp.toStringAsFixed(1)}°C',
                  onChanged: (val) {
                    ref.read(ambientTempProvider.notifier).state = val;
                  },
                ),
              ),
              Text(
                '${ambientTemp.toStringAsFixed(1)}°C',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryTextColor),
              ),
            ],
          ),

          // Humidity Slider Row
          Row(
            children: [
              const SizedBox(
                width: 75,
                child: Text('RH (%):', style: TextStyle(fontSize: 11)),
              ),
              Expanded(
                child: Slider(
                  value: ambientHumidity,
                  min: 20.0,
                  max: 98.0,
                  divisions: 78,
                  activeColor: AppColors.statusInfo,
                  label: '${ambientHumidity.toStringAsFixed(0)}%',
                  onChanged: (val) {
                    ref.read(ambientHumidityProvider.notifier).state = val;
                  },
                ),
              ),
              Text(
                '${ambientHumidity.toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryTextColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVpdGradientBar(double currentVpd, Color activeColor) {
    // Clamp marker position percentage between 0.0 and 2.2 kPa
    final double markerPct = (currentVpd / 2.2).clamp(0.02, 0.98);

    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth;

        return Column(
          children: [
            // Gauge Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 10,
                width: barWidth,
                child: Row(
                  children: [
                    // Under-transpiration: 0 - 0.4 (18%)
                    Expanded(flex: 18, child: Container(color: AppColors.statusInfo)),
                    // Early veg: 0.4 - 0.8 (18%)
                    Expanded(flex: 18, child: Container(color: AppColors.mintAccent)),
                    // Ideal veg: 0.8 - 1.2 (18%)
                    Expanded(flex: 18, child: Container(color: AppColors.statusOptimal)),
                    // Ideal generative: 1.2 - 1.6 (18%)
                    Expanded(flex: 18, child: Container(color: const Color(0xFFE9C46A))),
                    // Over-transpiration: 1.6+ (28%)
                    Expanded(flex: 28, child: Container(color: AppColors.statusCritical)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),

            // Pin Marker
            SizedBox(
              height: 14,
              child: Stack(
                children: [
                  Positioned(
                    left: (barWidth * markerPct) - 6,
                    child: const Icon(
                      Icons.arrow_drop_up,
                      size: 16,
                      color: AppColors.mintAccent,
                    ),
                  ),
                ],
              ),
            ),

            // Range Labels
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0.0 (Rot)', style: TextStyle(fontSize: 9, color: AppColors.textDarkSecondary)),
                Text('0.8 (Optimal Veg)', style: TextStyle(fontSize: 9, color: AppColors.textDarkSecondary)),
                Text('1.6+ (Dehydrate)', style: TextStyle(fontSize: 9, color: AppColors.textDarkSecondary)),
              ],
            ),
          ],
        );
      },
    );
  }

  Color _getZoneColor(VpdZone zone) {
    switch (zone) {
      case VpdZone.underTranspiration:
        return AppColors.statusInfo;
      case VpdZone.earlyVegetative:
        return AppColors.mintAccent;
      case VpdZone.optimalVegetative:
        return AppColors.statusOptimal;
      case VpdZone.optimalGenerative:
        return const Color(0xFFE9C46A);
      case VpdZone.overTranspirationStress:
        return AppColors.statusCritical;
    }
  }
}
