import 'package:aquagrow_mobile/core/constants/app_constants.dart';
import 'package:aquagrow_mobile/core/models/sensor_reading.dart';
import 'package:aquagrow_mobile/core/simulation/pod_simulator.dart';
import 'package:aquagrow_mobile/data/simulation/sim_repositories.dart';
import 'package:aquagrow_mobile/features/sync/application/sync_service.dart';
import 'package:aquagrow_mobile/features/sync/domain/sync_queue.dart';
import 'package:aquagrow_mobile/features/sync/domain/telemetry_uploader.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records every batch, and fails while [failing] is true.
class FakeUploader implements TelemetryUploader {
  final batches = <List<SensorReading>>[];
  bool failing = false;

  int get total => batches.fold(0, (sum, b) => sum + b.length);

  @override
  Future<void> upload(List<SensorReading> readings) async {
    if (failing) throw Exception('server unreachable');
    batches.add(List.of(readings));
  }
}

SensorReading reading(int i) => SensorReading(
      id: 'r$i',
      deviceId: 'pod-alpha',
      ph: 6,
      tdsPpm: 800,
      ecMs: 1.6,
      waterTempC: 21,
      waterLevelPct: 80,
      recordedAt: DateTime(2026, 11, 15, 10).add(Duration(seconds: 2 * i)),
    );

void main() {
  final now = DateTime(2026, 11, 15, 10, 30);
  late InMemorySyncQueue queue;
  late FakeUploader uploader;
  late List<SensorReading> cached;
  late SyncService service;

  setUp(() {
    queue = InMemorySyncQueue(capacity: AppConstants.maxOfflineQueueItems);
    uploader = FakeUploader();
    cached = [];
    service = SyncService(
      queue: queue,
      uploader: uploader,
      cache: (r) async => cached.add(r),
      clock: () => now,
    );
  });

  tearDown(() => service.dispose());

  Future<void> feed(int count, {int from = 0}) async {
    for (var i = from; i < from + count; i++) {
      await service.onReading(reading(i));
    }
  }

  test('caches every reading, online or offline', () async {
    await service.setOffline(false);
    await feed(3);
    await service.setOffline(true);
    await feed(2, from: 3);

    expect(cached, hasLength(5));
  });

  test('does not queue readings while online', () async {
    await service.setOffline(false);
    await feed(5);

    expect(queue.length, 0);
    expect(service.state.pending, 0);
  });

  test('the queue grows while offline', () async {
    await service.setOffline(true);
    await feed(10);

    expect(queue.length, 10);
    expect(service.state.pending, 10);
    expect(service.state.offline, isTrue);
    expect(uploader.batches, isEmpty);
  });

  test('flushes on reconnect in batches of 50, then clears', () async {
    await service.setOffline(true);
    await feed(120);

    await service.setOffline(false);

    expect(uploader.batches.map((b) => b.length), [50, 50, 20]);
    expect(uploader.batches.first.first.id, 'r0', reason: 'oldest first');
    expect(queue.length, 0);
    expect(service.state.pending, 0);
    expect(service.state.lastSyncedAt, now);
    expect(service.state.lastSyncedCount, 120);
  });

  test('announces how many readings were synced', () async {
    final counts = <int>[];
    service.syncedCounts.listen(counts.add);
    await service.setOffline(true);
    await feed(37);

    await service.setOffline(false);
    await pumpEventQueue();

    expect(counts, [37]);
  });

  test('never exceeds maxOfflineQueueItems, keeping the newest', () async {
    await service.setOffline(true);
    await feed(AppConstants.maxOfflineQueueItems + 25);

    expect(queue.length, AppConstants.maxOfflineQueueItems);
    expect(queue.peek(1).single.id, 'r25');
  });

  test('a failed upload keeps the readings for the next reconnect', () async {
    await service.setOffline(true);
    await feed(60);
    uploader.failing = true;

    await service.setOffline(false);

    expect(queue.length, 60);
    expect(service.state.lastSyncedAt, isNull);

    uploader.failing = false;
    await service.setOffline(true);
    await service.setOffline(false);

    expect(uploader.total, 60);
    expect(queue.length, 0);
  });

  test('a reading seen twice is queued and uploaded once', () async {
    await service.setOffline(true);
    await service.onReading(reading(1));
    await service.onReading(reading(1));

    await service.setOffline(false);

    expect(uploader.total, 1);
  });

  test('starting online uploads readings left from last time', () async {
    await queue.add(reading(1));
    await queue.add(reading(2));
    final fresh = SyncService(
      queue: queue,
      uploader: uploader,
      cache: (_) async {},
      clock: () => now,
    );
    addTearDown(fresh.dispose);

    expect(fresh.state.pending, 2);
    await fresh.setOffline(false);

    expect(uploader.total, 2);
  });

  test('a broken cache does not stop readings being queued', () async {
    final broken = SyncService(
      queue: queue,
      uploader: uploader,
      cache: (_) async => throw Exception('disk full'),
    );
    addTearDown(broken.dispose);

    await broken.setOffline(true);
    await broken.onReading(reading(1));

    expect(queue.length, 1);
  });

  test('watchPods queues live simulator readings while offline', () async {
    final sim = PodSimulator(clock: () => DateTime(2026, 11, 15, 10));
    final telemetry = SimTelemetryRepository(sim);
    await service.setOffline(true);

    service.watchPods(sim.pods, telemetry);
    await pumpEventQueue();
    sim.tick();
    await pumpEventQueue();

    expect(queue.length, greaterThanOrEqualTo(sim.pods.length));
    expect(cached.map((r) => r.deviceId).toSet(), {'pod-alpha', 'pod-beta'});
  });
}
