import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Average telemetry reading for a pod over the past 24 hours.
final cropTodayTelemetryProvider =
    FutureProvider.family<({double? avgPh, double? avgEc}), String>(
  (ref, podId) async {
    final repo = ref.watch(telemetryRepositoryProvider);
    final now = DateTime.now();
    final from = now.subtract(const Duration(hours: 24));
    final readings = await repo.history(podId, from: from, to: now);

    if (readings.isEmpty) {
      return (avgPh: null, avgEc: null);
    }

    final sumPh = readings.fold<double>(0.0, (sum, r) => sum + r.ph);
    final sumEc = readings.fold<double>(0.0, (sum, r) => sum + r.ecMs);

    return (
      avgPh: sumPh / readings.length,
      avgEc: sumEc / readings.length,
    );
  },
);
