import 'package:aquagrow_mobile/core/interfaces/i_telemetry_repository.dart';
import 'package:aquagrow_mobile/core/models/sensor_metric.dart';
import 'package:aquagrow_mobile/core/models/sensor_reading.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/features/insights/application/history_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTelemetryRepository implements ITelemetryRepository {
  DateTime? lastFrom;
  DateTime? lastTo;
  String? lastPodId;
  List<SensorReading> resultToReturn = [];

  @override
  Future<List<SensorReading>> history(
    String podId, {
    required DateTime from,
    required DateTime to,
  }) async {
    lastPodId = podId;
    lastFrom = from;
    lastTo = to;
    return resultToReturn;
  }

  @override
  Future<SensorReading> latestReading(String podId) =>
      throw UnimplementedError();

  @override
  Stream<SensorReading> watchReadings(String podId) =>
      throw UnimplementedError();
}

void main() {
  group('historyProviders', () {
    test(
        'historyRangeProvider defaults to 24 hours and can be changed to 7 days',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(historyRangeProvider), HistoryRange.hours24);

      container.read(historyRangeProvider.notifier).state = HistoryRange.days7;
      expect(container.read(historyRangeProvider), HistoryRange.days7);
    });

    test('historyMetricProvider defaults to pH and can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(historyMetricProvider), SensorMetric.ph);

      container.read(historyMetricProvider.notifier).state = SensorMetric.ec;
      expect(container.read(historyMetricProvider), SensorMetric.ec);
    });

    test('historyProvider queries repository with 24 hours by default',
        () async {
      final fakeRepo = _FakeTelemetryRepository();
      final now = DateTime(2026, 11, 15, 12, 0);

      final container = ProviderContainer(
        overrides: [
          selectedPodIdProvider.overrideWith((ref) => 'pod-alpha'),
          telemetryRepositoryProvider.overrideWithValue(fakeRepo),
          clockProvider.overrideWithValue(() => now),
        ],
      );
      addTearDown(container.dispose);

      await container.read(historyProvider.future);

      expect(fakeRepo.lastPodId, 'pod-alpha');
      expect(fakeRepo.lastTo, now);
      expect(fakeRepo.lastFrom, now.subtract(const Duration(hours: 24)));
    });

    test('historyProvider queries repository with 7 days when range is switched',
        () async {
      final fakeRepo = _FakeTelemetryRepository();
      final now = DateTime(2026, 11, 15, 12, 0);

      final container = ProviderContainer(
        overrides: [
          selectedPodIdProvider.overrideWith((ref) => 'pod-alpha'),
          telemetryRepositoryProvider.overrideWithValue(fakeRepo),
          clockProvider.overrideWithValue(() => now),
        ],
      );
      addTearDown(container.dispose);

      container.read(historyRangeProvider.notifier).state = HistoryRange.days7;
      await container.read(historyProvider.future);

      expect(fakeRepo.lastPodId, 'pod-alpha');
      expect(fakeRepo.lastTo, now);
      expect(fakeRepo.lastFrom, now.subtract(const Duration(days: 7)));
    });

    test('historyStatsProvider computes stats for active readings and metric',
        () async {
      final fakeRepo = _FakeTelemetryRepository();
      final now = DateTime(2026, 11, 15, 12, 0);
      fakeRepo.resultToReturn = [
        SensorReading(
          id: 'reading-1',
          deviceId: 'pod-alpha',
          recordedAt: now.subtract(const Duration(hours: 1)),
          ph: 6.0,
          tdsPpm: 750.0,
          ecMs: 1.5,
          waterTempC: 22.0,
          waterLevelPct: 80.0,
        ),
        SensorReading(
          id: 'reading-2',
          deviceId: 'pod-alpha',
          recordedAt: now,
          ph: 6.4,
          tdsPpm: 800.0,
          ecMs: 1.6,
          waterTempC: 23.0,
          waterLevelPct: 82.0,
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          selectedPodIdProvider.overrideWith((ref) => 'pod-alpha'),
          telemetryRepositoryProvider.overrideWithValue(fakeRepo),
          clockProvider.overrideWithValue(() => now),
        ],
      );
      addTearDown(container.dispose);

      await container.read(historyProvider.future);
      final stats = container.read(historyStatsProvider);

      expect(stats.sampleCount, 2);
      expect(stats.min, 6.0);
      expect(stats.max, 6.4);
      expect(stats.average, 6.2);
    });
  });
}
