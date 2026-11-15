import 'package:aquagrow_mobile/core/models/vpd_reading.dart';
import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/features/location/application/location_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Interactive Vapor Pressure Deficit (VPD) gauge card displaying real-time
/// canopy transpiration health, psychrometric breakdown, and horticultural advice.
///
/// Restyled strictly to Figma design tokens (`context.ag`, `AgSpace`, `AgRadius`).
class VpdGaugeCard extends ConsumerWidget {
  const VpdGaugeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vpd = ref.watch(vpdReadingProvider);
    final colors = context.ag;
    final textTheme = Theme.of(context).textTheme;
    final zoneTone = _getZoneColors(vpd.zone, colors);

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
          // Header Row: Icon, Title, and Optimal Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AgSpace.s8),
                      decoration: BoxDecoration(
                        color: zoneTone.surface,
                        borderRadius: AgRadius.all(AgRadius.r16),
                      ),
                      child: Icon(Icons.eco, color: zoneTone.primary, size: 20),
                    ),
                    const SizedBox(width: AgSpace.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vapor Pressure Deficit (VPD)',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colors.text,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Air dryness for your plants',
                            style: textTheme.labelSmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AgSpace.s8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AgSpace.s8,
                  vertical: AgSpace.s4,
                ),
                decoration: BoxDecoration(
                  color: zoneTone.surface,
                  borderRadius: AgRadius.all(AgRadius.pill),
                  border: Border.all(
                    color: zoneTone.primary.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  vpd.isOptimal ? 'OPTIMAL' : 'ATTENTION',
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: zoneTone.primary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AgSpace.s16),

          // Core Gauge Display: kPa Large Value + Psychrometric Breakdown
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                vpd.vpdKpa.toStringAsFixed(2),
                style: textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: colors.text,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: AgSpace.s8),
              Text(
                'kPa',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(width: AgSpace.s8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      vpd.statusTitle,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.text,
                      ),
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AgSpace.s4),
                    Text(
                      _getZoneAdviceSubtitle(vpd.zone),
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AgSpace.s16),

          // Visual Gradient Bar
          _buildVpdGradientBar(context, vpd.vpdKpa, zoneTone.primary),

          const SizedBox(height: AgSpace.s16),

          // Live Ambient Telemetry Reading Info Row
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AgSpace.s12,
              vertical: AgSpace.s8,
            ),
            decoration: BoxDecoration(
              color: colors.subtle,
              borderRadius: AgRadius.all(AgRadius.r16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.thermostat, size: 16, color: colors.brand),
                      const SizedBox(width: AgSpace.s4),
                      Flexible(
                        child: Text(
                          'Air Temp: ${vpd.airTemperatureC.toStringAsFixed(1)}°C',
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.text,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AgSpace.s8),
                Row(
                  children: [
                    Icon(Icons.water_drop, size: 16, color: colors.brand),
                    const SizedBox(width: AgSpace.s4),
                    Text(
                      'RH: ${vpd.relativeHumidityPct.toStringAsFixed(0)}%',
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.text,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AgSpace.s12),

          // Actionable Horticultural Guidance Banner
          Container(
            padding: const EdgeInsets.all(AgSpace.s12),
            decoration: BoxDecoration(
              color: zoneTone.surface,
              borderRadius: AgRadius.all(AgRadius.r16),
              border:
                  Border.all(color: zoneTone.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.tips_and_updates_outlined,
                  color: zoneTone.primary,
                  size: 20,
                ),
                const SizedBox(width: AgSpace.s12),
                Expanded(
                  child: Text(
                    vpd.actionableAdvice,
                    style: textTheme.bodySmall?.copyWith(
                      height: 1.4,
                      color: colors.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVpdGradientBar(
    BuildContext context,
    double currentVpd,
    Color activeColor,
  ) {
    final colors = context.ag;
    final textTheme = Theme.of(context).textTheme;
    final double markerPct = (currentVpd / 2.2).clamp(0.02, 0.98);

    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth;

        return Column(
          children: [
            // Segmented colored gauge bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 8,
                width: barWidth,
                child: Row(
                  children: [
                    // Under-transpiration: 0 - 0.4
                    Expanded(
                      flex: 18,
                      child: Container(
                        color: colors.warning.withValues(alpha: 0.6),
                      ),
                    ),
                    // Early veg: 0.4 - 0.8
                    Expanded(
                      flex: 18,
                      child: Container(
                        color: colors.brand.withValues(alpha: 0.7),
                      ),
                    ),
                    // Ideal veg: 0.8 - 1.2
                    Expanded(flex: 18, child: Container(color: colors.brand)),
                    // Ideal generative: 1.2 - 1.6
                    Expanded(flex: 18, child: Container(color: colors.warning)),
                    // Over-transpiration: 1.6+
                    Expanded(
                      flex: 28,
                      child: Container(color: colors.critical),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AgSpace.s4),

            // Pin Marker
            SizedBox(
              height: 14,
              child: Stack(
                children: [
                  Positioned(
                    left: (barWidth * markerPct) - 6,
                    child: Icon(
                      Icons.arrow_drop_up,
                      size: 16,
                      color: colors.text,
                    ),
                  ),
                ],
              ),
            ),

            // Range Labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    '0.0 (Low)',
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Flexible(
                  child: Text(
                    '0.8–1.2 (Ideal)',
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.text,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Flexible(
                  child: Text(
                    '1.6+ (Dry)',
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  _ZoneTone _getZoneColors(VpdZone zone, AgColors colors) {
    switch (zone) {
      case VpdZone.underTranspiration:
        return _ZoneTone(
          primary: colors.warning,
          surface: colors.warningSurface,
        );
      case VpdZone.earlyVegetative:
        return _ZoneTone(primary: colors.brand, surface: colors.brandSurface);
      case VpdZone.optimalVegetative:
        return _ZoneTone(primary: colors.brand, surface: colors.brandSurface);
      case VpdZone.optimalGenerative:
        return _ZoneTone(
          primary: colors.warning,
          surface: colors.warningSurface,
        );
      case VpdZone.overTranspirationStress:
        return _ZoneTone(
          primary: colors.critical,
          surface: colors.criticalSurface,
        );
    }
  }

  String _getZoneAdviceSubtitle(VpdZone zone) {
    switch (zone) {
      case VpdZone.underTranspiration:
        return 'Too humid for leafy greens';
      case VpdZone.earlyVegetative:
        return 'Gentle for young seedlings';
      case VpdZone.optimalVegetative:
        return 'Good for leafy greens';
      case VpdZone.optimalGenerative:
        return 'Good for flowering crops';
      case VpdZone.overTranspirationStress:
        return 'Too dry for leafy greens';
    }
  }
}

class _ZoneTone {
  const _ZoneTone({required this.primary, required this.surface});
  final Color primary;
  final Color surface;
}
