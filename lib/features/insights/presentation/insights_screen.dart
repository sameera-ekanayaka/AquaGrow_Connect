import 'dart:convert';

import 'package:aquagrow_mobile/app/router/app_routes.dart';
import 'package:aquagrow_mobile/app/shell/tab_header.dart';
import 'package:aquagrow_mobile/core/models/sensor_metric.dart';
import 'package:aquagrow_mobile/core/models/sensor_reading.dart';
import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/features/insights/application/history_providers.dart';
import 'package:aquagrow_mobile/features/insights/application/insights_refresh_action.dart';
import 'package:aquagrow_mobile/features/insights/application/shake_detector.dart';
import 'package:aquagrow_mobile/features/insights/application/shake_detector_provider.dart';
import 'package:aquagrow_mobile/features/insights/domain/readings_csv.dart';
import 'package:aquagrow_mobile/features/insights/presentation/widgets/shake_feedback.dart';
import 'package:aquagrow_mobile/features/insights/presentation/widgets/telemetry_history_chart.dart';
import 'package:aquagrow_mobile/features/insights/presentation/widgets/trend_chip.dart';
import 'package:aquagrow_mobile/features/location/presentation/vpd_gauge_card.dart';
import 'package:aquagrow_mobile/features/location/presentation/weather_summary_card.dart';
import 'package:aquagrow_mobile/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Insights tab: charts of past readings, plus weather and VPD advice.
///
/// Supports shake-to-refresh: vigorous shaking (g-force > 2.7g) re-queries
/// telemetry, ambient weather, and location state.
///
/// OWNER: Imasha (see docs/tasks/imasha.md).
class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  ShakeDetector? _shakeDetector;

  /// True while this tab is the one on screen.
  bool _tabVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initShakeDetector();
    });
  }

  void _initShakeDetector() {
    final config = ref.read(shakeDetectorConfigProvider);
    final stream = ref.read(shakeDetectorStreamProvider);
    final clock = ref.read(shakeDetectorClockProvider);

    _shakeDetector = ShakeDetector(
      config: config,
      sensorStream: stream,
      clock: clock,
      onShake: _handleShake,
    );
    _syncShakeWithVisibility();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tabVisible = TickerMode.of(context);
    _syncShakeWithVisibility();
  }

  /// Listens for shakes only while the Insights tab is visible.
  void _syncShakeWithVisibility() {
    final detector = _shakeDetector;
    if (detector == null) return;
    if (_tabVisible) {
      detector.start();
    } else {
      detector.stop();
    }
  }

  void _handleShake() {
    if (!mounted) return;
    refreshInsightsData(ref);
    ShakeFeedback.show(context);
  }

  Future<void> _exportReadings() async {
    final historyAsync = ref.read(historyProvider);
    final readings = historyAsync.valueOrNull ?? const [];
    if (readings.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No readings to export yet')),
        );
      }
      return;
    }

    final selectedPod = ref.read(selectedPodProvider);
    final now = ref.read(clockProvider)();
    final podName = selectedPod?.name ?? 'pod';
    final fileName = buildCsvFileName(podName: podName, now: now);
    final csvString = readingsToCsv(readings);

    await ref.read(shareServiceProvider).shareBytes(
          bytes: utf8.encode(csvString),
          fileName: fileName,
          mimeType: 'text/csv',
        );
  }

  @override
  void dispose() {
    _shakeDetector?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ag;
    final selectedPod = ref.watch(selectedPodProvider);
    final selectedMetric = ref.watch(historyMetricProvider);
    final selectedRange = ref.watch(historyRangeProvider);
    final historyAsync = ref.watch(historyProvider);
    final stats = ref.watch(historyStatsProvider);

    final podSubtitle = selectedPod != null
        ? selectedPod.displayName
        : 'How your pods are doing';

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AgSpace.screen),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TabHeader(
                  subtitle: podSubtitle,
                  title: 'Insights',
                ),
              ),
              IconButton(
                icon: const Icon(Icons.file_download_outlined),
                tooltip: 'Export readings',
                onPressed: _exportReadings,
              ),
            ],
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
                    // Minimal UI: pills, the selected one near-black.
                    shape: const StadiumBorder(),
                    selectedColor: colors.text,
                    backgroundColor: colors.surface,
                    side: BorderSide.none,
                    labelStyle: TextStyle(
                      color: isSelected ? colors.onDark : colors.text,
                      fontWeight: FontWeight.w600,
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

          // Short-term trend warning chip
          const TrendChip(),

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
