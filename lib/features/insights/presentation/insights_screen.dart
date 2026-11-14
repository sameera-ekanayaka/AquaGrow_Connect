import 'package:aquagrow_mobile/app/router/app_routes.dart';
import 'package:aquagrow_mobile/app/shell/tab_header.dart';
import 'package:aquagrow_mobile/core/models/sensor_metric.dart';
import 'package:aquagrow_mobile/core/models/sensor_reading.dart';
import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/features/insights/application/history_providers.dart';
import 'package:aquagrow_mobile/features/insights/presentation/widgets/telemetry_history_chart.dart';
import 'package:aquagrow_mobile/features/location/presentation/vpd_gauge_card.dart';
import 'package:aquagrow_mobile/features/location/presentation/weather_summary_card.dart';
import 'package:aquagrow_mobile/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Insights tab: charts of past readings, plus weather and VPD advice.
///
/// OWNER: Imasha (see docs/tasks/imasha.md).
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.ag;
    final selectedPod = ref.watch(selectedPodProvider);
    final selectedMetric = ref.watch(historyMetricProvider);
    final selectedRange = ref.watch(historyRangeProvider);
    final historyAsync = ref.watch(historyProvider);
    final stats = ref.watch(historyStatsProvider);

    final podSubtitle = selectedPod != null
        ? selectedPod.displayName
        : 'HOW YOUR PODS ARE DOING';

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AgSpace.screen),
        children: [
          TabHeader(
            overline: podSubtitle.toUpperCase(),
            title: 'Insights',
          ),

          const SizedBox(height: AgSpace.s12),

          // Metric selector chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: SensorMetric.values.map((metric) {
                final isSelected = metric == selectedMetric;
                return Padding(
                  padding: const EdgeInsets.only(right: AgSpace.s8),
                  child: FilterChip(
                    label: Text(metric.label),
                    selected: isSelected,
                    showCheckmark: false,
                    selectedColor: colors.brandSurface,
                    backgroundColor: colors.surface,
                    side: BorderSide(
                      color: isSelected ? colors.brand : colors.border,
                      width: 1.5,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? colors.text : colors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    onSelected: (_) {
                      ref.read(historyMetricProvider.notifier).state = metric;
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: AgSpace.s12),

          // Time range selector (24 hours / 7 days)
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<HistoryRange>(
              segments: const [
                ButtonSegment<HistoryRange>(
                  value: HistoryRange.hours24,
                  label: Text('24 hours'),
                ),
                ButtonSegment<HistoryRange>(
                  value: HistoryRange.days7,
                  label: Text('7 days'),
                ),
              ],
              selected: {selectedRange},
              onSelectionChanged: (newSelection) {
                if (newSelection.isNotEmpty) {
                  ref.read(historyRangeProvider.notifier).state =
                      newSelection.first;
                }
              },
              style: ButtonStyle(
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: AgRadius.all(AgRadius.r16),
                  ),
                ),
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return colors.brandSurface;
                  }
                  return colors.surface;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return colors.text;
                  }
                  return colors.textSecondary;
                }),
              ),
            ),
          ),

          const SizedBox(height: AgSpace.s16),

          // Historical chart card with loading/error/empty state handling
          AsyncValueView<List<SensorReading>>(
            value: historyAsync,
            isEmpty: (data) => data.isEmpty,
            empty: const EmptyView(
              icon: Icons.show_chart,
              title: 'No telemetry history',
              message: 'No sensor readings were recorded for this pod yet.',
            ),
            onRetry: () => ref.refresh(historyProvider),
            data: (readings) => TelemetryHistoryChart(
              readings: readings,
              metric: selectedMetric,
              range: selectedRange,
              stats: stats,
            ),
          ),

          const SizedBox(height: AgSpace.s16),

          // Weather and VPD section header with shortcut to microclimate controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weather and VPD',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.text,
                    ),
              ),
              TextButton(
                onPressed: () {
                  if (GoRouter.maybeOf(context) != null) {
                    context.push(AppRoutes.microclimate);
                  }
                },
                child: const Text('Controls'),
              ),
            ],
          ),

          const SizedBox(height: AgSpace.s8),

          // Hyper-local ambient weather summary
          const WeatherSummaryCard(),

          const SizedBox(height: AgSpace.s16),

          // Real-time canopy transpiration VPD gauge
          const VpdGaugeCard(),
        ],
      ),
    );
  }
}
