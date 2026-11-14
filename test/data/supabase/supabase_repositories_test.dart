import 'dart:async';

import 'package:aquagrow_mobile/core/errors/app_failure.dart';
import 'package:aquagrow_mobile/core/models/sensor_reading.dart';
import 'package:aquagrow_mobile/data/supabase/supabase_pod_repository.dart';
import 'package:aquagrow_mobile/data/supabase/supabase_telemetry_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeDeviceSource implements DeviceSource {
  List<Map<String, dynamic>> rows = [];
  bool failing = false;
  final changesController = StreamController<void>.broadcast();

  Future<void> dispose() => changesController.close();

  @override
  Future<List<Map<String, dynamic>>> fetchDevices() async {
    if (failing) throw Exception('offline');
    return rows;
  }

  @override
  Stream<void> changes() => changesController.stream;
}

class FakeTelemetrySource implements TelemetrySource {
  Map<String, dynamic>? latest;
  List<Map<String, dynamic>> range = [];
  bool failing = false;
  final insertsController = StreamController<Map<String, dynamic>>.broadcast();

  Future<void> dispose() => insertsController.close();

  @override
  Future<Map<String, dynamic>?> fetchLatest(String podId) async {
    if (failing) throw Exception('offline');
    return latest;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchRange(
    String podId, {
    required DateTime from,
    required DateTime to,
  }) async {
    if (failing) throw Exception('offline');
    return range;
  }

  @override
  Stream<Map<String, dynamic>> inserts(String podId) =>
      insertsController.stream;
}

Map<String, dynamic> row(String id, int hour, {double ph = 6.0}) => {
      'id': hour,
      'reading_id': id,
      'device_id': 'd1',
      'ph': ph,
      'tds_ppm': 800,
      'ec_ms': 1.6,
      'water_temp_c': 21,
      'water_level_pct': 80,
      'recorded_at': DateTime.utc(2026, 11, 15, hour).toIso8601String(),
    };

SensorReading cachedReading(String id, int hour) => SensorReading(
      id: id,
      deviceId: 'd1',
      ph: 5.5,
      tdsPpm: 800,
      ecMs: 1.6,
      waterTempC: 21,
      waterLevelPct: 80,
      recordedAt: DateTime.utc(2026, 11, 15, hour).toLocal(),
    );

void main() {
  group('SupabasePodRepository', () {
    test('loads pods and reloads them when a device changes', () async {
      final source = FakeDeviceSource()
        ..rows = [
          {'id': 'd1', 'device_name': 'Pod Alpha', 'room': 'Kitchen'},
        ];
      addTearDown(source.dispose);
      final repo = SupabasePodRepository(source);
      final emitted = <List<String>>[];
      final sub = repo
          .watchPods()
          .listen((pods) => emitted.add(pods.map((p) => p.name).toList()));

      await pumpEventQueue();
      source.rows = [
        {'id': 'd1', 'device_name': 'Pod Alpha', 'room': 'Kitchen'},
        {'id': 'd2', 'device_name': 'Pod Beta', 'room': 'Dining room'},
      ];
      source.changesController.add(null);
      await pumpEventQueue();

      expect(emitted, [
        ['Pod Alpha'],
        ['Pod Alpha', 'Pod Beta'],
      ]);
      await sub.cancel();
    });

    test('turns a failed load into a friendly NetworkFailure', () async {
      final source = FakeDeviceSource()..failing = true;
      addTearDown(source.dispose);
      final repo = SupabasePodRepository(source);

      expect(repo.getPods(), throwsA(isA<NetworkFailure>()));
      expect(repo.watchPods().first, throwsA(isA<NetworkFailure>()));
    });

    test('cancelling stops listening for device changes at once', () async {
      final source = FakeDeviceSource();
      addTearDown(source.dispose);
      final sub = SupabasePodRepository(source).watchPods().listen((_) {});
      await pumpEventQueue();

      await sub.cancel();

      expect(source.changesController.hasListener, isFalse);
    });

    test('keeps the last list when a refresh fails', () async {
      final source = FakeDeviceSource()
        ..rows = [
          {'id': 'd1', 'device_name': 'Pod Alpha'},
        ];
      addTearDown(source.dispose);
      final emitted = <int>[];
      final sub = SupabasePodRepository(source)
          .watchPods()
          .listen((pods) => emitted.add(pods.length));

      await pumpEventQueue();
      source.failing = true;
      source.changesController.add(null);
      await pumpEventQueue();

      expect(emitted, [1]);
      await sub.cancel();
    });
  });

  group('SupabaseTelemetryRepository', () {
    late FakeTelemetrySource source;
    late List<SensorReading> cache;
    late SupabaseTelemetryRepository repo;

    setUp(() {
      source = FakeTelemetrySource();
      cache = [];
      repo = SupabaseTelemetryRepository(source, cached: (_) => cache);
      addTearDown(source.dispose);
    });

    test('latestReading returns the newest server row', () async {
      source.latest = row('r9', 9, ph: 6.4);

      final r = await repo.latestReading('d1');

      expect(r.id, 'r9');
      expect(r.ph, 6.4);
    });

    test('latestReading falls back to the cache when offline', () async {
      source.failing = true;
      cache = [cachedReading('c1', 7), cachedReading('c2', 8)];

      expect((await repo.latestReading('d1')).id, 'c2');
    });

    test('latestReading explains when offline with no cache', () async {
      source.failing = true;

      expect(repo.latestReading('d1'), throwsA(isA<NetworkFailure>()));
    });

    test('latestReading says no readings yet for a new pod', () async {
      expect(repo.latestReading('d1'), throwsA(isA<DeviceFailure>()));
    });

    test('history returns server rows', () async {
      source.range = [row('a', 8), row('b', 9)];

      final h = await repo.history(
        'd1',
        from: DateTime.utc(2026, 11, 15),
        to: DateTime.utc(2026, 11, 16),
      );

      expect(h.map((r) => r.id), ['a', 'b']);
    });

    test('history falls back to cached readings in range, oldest first',
        () async {
      source.failing = true;
      cache = [
        cachedReading('late', 12),
        cachedReading('outside', 2),
        cachedReading('early', 10),
      ];

      final h = await repo.history(
        'd1',
        from: DateTime.utc(2026, 11, 15, 9).toLocal(),
        to: DateTime.utc(2026, 11, 15, 13).toLocal(),
      );

      expect(h.map((r) => r.id), ['early', 'late']);
    });

    test('watchReadings emits the latest, then each new realtime row',
        () async {
      source.latest = row('r1', 8);
      final ids = <String>[];
      final sub = repo.watchReadings('d1').listen((r) => ids.add(r.id));

      await pumpEventQueue();
      source.insertsController.add(row('r2', 9));
      await pumpEventQueue();

      expect(ids, ['r1', 'r2']);
      await sub.cancel();
    });

    test('watchReadings reports no readings yet but keeps listening', () async {
      final ids = <String>[];
      final errors = <Object>[];
      final sub = repo
          .watchReadings('d1')
          .listen((r) => ids.add(r.id), onError: errors.add);

      await pumpEventQueue();
      source.insertsController.add(row('first', 9));
      await pumpEventQueue();

      expect(errors.single, isA<DeviceFailure>());
      expect(ids, ['first']);
      await sub.cancel();
    });
  });
}
