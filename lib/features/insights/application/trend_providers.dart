import 'package:aquagrow_mobile/features/insights/application/history_providers.dart';
import 'package:aquagrow_mobile/features/insights/domain/trend_forecast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides a trend forecast warning for the currently selected metric and pod,
/// or `null` when telemetry is stable, out of range, or insufficient.
final trendProvider = Provider<TrendForecast?>((ref) {
  final readings = ref.watch(historyProvider).valueOrNull ?? const [];
  if (readings.isEmpty) return null;

  final metric = ref.watch(historyMetricProvider);
  final now = ref.watch(clockProvider)();

  return computeTrend(
    readings: readings,
    metric: metric,
    now: now,
  );
});
