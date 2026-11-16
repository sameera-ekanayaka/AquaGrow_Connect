import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/features/insights/application/trend_providers.dart';
import 'package:aquagrow_mobile/features/insights/domain/trend_forecast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A chip/card showing short-term telemetry trend warnings.
///
/// Automatically hides when no trend forecast is available.
class TrendChip extends ConsumerWidget {
  /// Creates a trend forecast notification chip.
  const TrendChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecast = ref.watch(trendProvider);
    if (forecast == null) return const SizedBox.shrink();

    final colors = context.ag;
    final textTheme = Theme.of(context).textTheme;

    final isWarning = forecast.timeToLeaveRange != null;
    final backgroundColor =
        isWarning ? colors.warningSurface : colors.brandSurface;
    final borderColor = isWarning ? colors.warning : colors.brand;
    final iconColor = isWarning ? colors.warning : colors.text;

    final icon = switch (forecast.direction) {
      TrendDirection.rising => Icons.trending_up,
      TrendDirection.falling => Icons.trending_down,
      TrendDirection.steady => Icons.trending_flat,
    };

    return Semantics(
      label: forecast.message,
      child: Container(
        margin: const EdgeInsets.only(bottom: AgSpace.s12),
        padding: const EdgeInsets.symmetric(
          horizontal: AgSpace.s12,
          vertical: AgSpace.s8,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: AgRadius.all(AgRadius.r16),
          border: Border.all(
            color: borderColor.withValues(alpha: 0.5),
            width: 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: iconColor,
            ),
            const SizedBox(width: AgSpace.s8),
            Expanded(
              child: Text(
                forecast.message,
                style: textTheme.bodySmall?.copyWith(
                  color: colors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
