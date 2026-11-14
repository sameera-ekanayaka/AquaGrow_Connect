import 'dart:async';

import 'package:aquagrow_mobile/core/errors/app_failure.dart';
import 'package:aquagrow_mobile/core/interfaces/i_telemetry_repository.dart';
import 'package:aquagrow_mobile/core/logging/app_logger.dart';
import 'package:aquagrow_mobile/core/models/sensor_reading.dart';
import 'package:aquagrow_mobile/data/supabase/supabase_rows.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _log = AppLogger('supabase');

/// Most rows one chart request reads (a week of readings every 2 minutes).
const kMaxHistoryRows = 5000;

/// Where telemetry rows come from. An interface so tests can use a fake.
abstract interface class TelemetrySource {
  /// The newest `telemetry_logs` row for [podId], or null if there is none.
  Future<Map<String, dynamic>?> fetchLatest(String podId);

  /// Rows for [podId] between [from] and [to], oldest first.
  Future<List<Map<String, dynamic>>> fetchRange(
    String podId, {
    required DateTime from,
    required DateTime to,
  });

  /// Every new row inserted for [podId] from now on.
  Stream<Map<String, dynamic>> inserts(String podId);
}

/// [TelemetrySource] backed by Supabase (REST for reads, realtime for inserts).
class SupabaseTelemetrySource implements TelemetrySource {
  /// Reads telemetry through [client].
  SupabaseTelemetrySource(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>?> fetchLatest(String podId) => _client
      .from('telemetry_logs')
      .select()
      .eq('device_id', podId)
      .order('recorded_at', ascending: false)
      .limit(1)
      .maybeSingle();

  @override
  Future<List<Map<String, dynamic>>> fetchRange(
    String podId, {
    required DateTime from,
    required DateTime to,
  }) =>
      _client
          .from('telemetry_logs')
          .select()
          .eq('device_id', podId)
          .gte('recorded_at', from.toUtc().toIso8601String())
          .lte('recorded_at', to.toUtc().toIso8601String())
          .order('recorded_at')
          .limit(kMaxHistoryRows);

  @override
  Stream<Map<String, dynamic>> inserts(String podId) {
    late final RealtimeChannel channel;
    late final StreamController<Map<String, dynamic>> controller;
    controller = StreamController<Map<String, dynamic>>(
      onListen: () {
        channel = _client
            .channel('telemetry-$podId')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'telemetry_logs',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'device_id',
                value: podId,
              ),
              callback: (payload) => controller.add(payload.newRecord),
            )
            .subscribe();
      },
      onCancel: () async {
        await _client.removeChannel(channel);
        await controller.close();
      },
    );
    return controller.stream;
  }
}

/// Live readings and chart history from Supabase `telemetry_logs`.
///
/// When Supabase cannot be reached, it falls back to the readings saved in
/// the local Hive cache (72 hours), so tiles and charts keep working offline.
class SupabaseTelemetryRepository implements ITelemetryRepository {
  /// Reads from [source], falling back to [cached] readings for a pod.
  SupabaseTelemetryRepository(
    this._source, {
    required List<SensorReading> Function(String podId) cached,
  }) : _cached = cached;

  final TelemetrySource _source;
  final List<SensorReading> Function(String podId) _cached;

  @override
  Future<SensorReading> latestReading(String podId) async {
    Map<String, dynamic>? row;
    try {
      row = await _source.fetchLatest(podId);
    } catch (e, s) {
      _log.error('Latest reading failed, using cache', e, s);
      final cached = _newestCached(podId);
      if (cached != null) return cached;
      throw NetworkFailure('No connection and no saved readings yet.', e);
    }
    if (row != null) return SupabaseRows.reading(row);
    final cached = _newestCached(podId);
    if (cached != null) return cached;
    throw const DeviceFailure('No readings from this pod yet.');
  }

  @override
  Future<List<SensorReading>> history(
    String podId, {
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final rows = await _source.fetchRange(podId, from: from, to: to);
      return rows.map(SupabaseRows.reading).toList(growable: false);
    } catch (e, s) {
      _log.error('History failed, using cache', e, s);
      final saved = _cached(podId)
          .where(
            (r) => !r.recordedAt.isBefore(from) && !r.recordedAt.isAfter(to),
          )
          .toList()
        ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
      if (saved.isNotEmpty) return saved;
      throw NetworkFailure('No connection and no saved readings yet.', e);
    }
  }

  @override
  Stream<SensorReading> watchReadings(String podId) async* {
    try {
      yield await latestReading(podId);
    } on AppFailure catch (e) {
      // Show why there is nothing yet, but keep listening for new readings.
      yield* Stream<SensorReading>.error(e);
    }
    yield* _source.inserts(podId).map(SupabaseRows.reading);
  }

  SensorReading? _newestCached(String podId) {
    final saved = _cached(podId);
    if (saved.isEmpty) return null;
    return saved.reduce((a, b) => a.recordedAt.isAfter(b.recordedAt) ? a : b);
  }
}
