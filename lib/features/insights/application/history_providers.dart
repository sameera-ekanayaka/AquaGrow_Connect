import 'package:aquagrow_mobile/core/models/sensor_metric.dart';
import 'package:aquagrow_mobile/core/models/sensor_reading.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/features/insights/domain/history_stats.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Supported history time windows for the Insights charts.
enum HistoryRange {
  hours24('24 hours', Duration(hours: 24)),
  days7('7 days', Duration(days: 7));

  const HistoryRange(this.label, this.duration);

  /// Human-readable label for UI buttons.
  final String label;

  /// Duration backwards from reference time.
  final Duration duration;
}

/// Clock provider allowing deterministic time in widget tests.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// The active historical time window ('24 hours' or '7 days').
final historyRangeProvider =
    StateProvider<HistoryRange>((ref) => HistoryRange.hours24);

/// The metric currently graphed on the historical chart.
final historyMetricProvider =
    StateProvider<SensorMetric>((ref) => SensorMetric.ph);

/// Asynchronously fetches telemetry history for the selected pod and range.
final historyProvider = FutureProvider<List<SensorReading>>((ref) async {
  final podId = ref.watch(selectedPodIdProvider);
  final range = ref.watch(historyRangeProvider);
  final repo = ref.watch(telemetryRepositoryProvider);
  final now = ref.watch(clockProvider)();
  final from = now.subtract(range.duration);

  return repo.history(podId, from: from, to: now);
});

/// Evaluates summary statistics (min, max, average, stability) for the active readings.
final historyStatsProvider = Provider<HistoryStats>((ref) {
  final readings = ref.watch(historyProvider).valueOrNull ?? const [];
  final metric = ref.watch(historyMetricProvider);
  return HistoryStats.compute(readings, metric);
});
