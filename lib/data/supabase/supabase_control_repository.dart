import 'dart:async';

import 'package:aquagrow_mobile/core/errors/app_failure.dart';
import 'package:aquagrow_mobile/core/interfaces/i_control_repository.dart';
import 'package:aquagrow_mobile/core/logging/app_logger.dart';
import 'package:aquagrow_mobile/core/models/actuator_state.dart';
import 'package:aquagrow_mobile/data/supabase/realtime_topics.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _log = AppLogger('supabase');

/// The `devices` columns the controls read.
const controlColumns =
    'id, is_online, pump_on, light_on, light_brightness, mist_on, '
    'ph_dose_requested_at';

/// Where a pod's control row comes from. An interface so tests can use a fake.
abstract interface class ControlSource {
  /// The control columns of device [podId].
  Future<Map<String, dynamic>> fetchDevice(String podId);

  /// Emits the device row of [podId] every time it changes.
  Stream<Map<String, dynamic>> deviceChanges(String podId);

  /// Updates columns of device [podId].
  Future<void> updateDevice(String podId, Map<String, dynamic> values);
}

/// [ControlSource] backed by Supabase (REST, and realtime for changes).
class SupabaseControlSource implements ControlSource {
  /// Reads and writes devices through [client].
  SupabaseControlSource(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>> fetchDevice(String podId) =>
      _client.from('devices').select(controlColumns).eq('id', podId).single();

  @override
  Future<void> updateDevice(String podId, Map<String, dynamic> values) =>
      _client.from('devices').update(values).eq('id', podId);

  @override
  Stream<Map<String, dynamic>> deviceChanges(String podId) {
    late final RealtimeChannel channel;
    late final StreamController<Map<String, dynamic>> controller;
    controller = StreamController<Map<String, dynamic>>(
      onListen: () {
        channel = _client
            .channel(RealtimeTopics.unique('controls-$podId'))
            .onPostgresChanges(
              event: PostgresChangeEvent.update,
              schema: 'public',
              table: 'devices',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'id',
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

/// Pump, light and doser commands for a real pod (live mode).
///
/// The app writes the wanted state on the pod's `devices` row; the pod (or
/// the 3D simulator) reads it through realtime and acts on it. pH-down and
/// refill are request timestamps, so each tap is a new request.
class SupabaseControlRepository implements IControlRepository {
  /// Sends commands through [source]. [clock] gives the request time.
  SupabaseControlRepository(this._source, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final ControlSource _source;
  final DateTime Function() _clock;

  /// The [ActuatorState] in a device row.
  static ActuatorState stateOf(Map<String, dynamic> row) => ActuatorState(
        pumpOn: (row['pump_on'] as bool?) ?? true,
        lightOn: (row['light_on'] as bool?) ?? true,
        lightBrightness: (row['light_brightness'] as num?)?.toInt() ?? 80,
        mistOn: (row['mist_on'] as bool?) ?? true,
        lastPhDoseAt: row['ph_dose_requested_at'] is String
            ? DateTime.tryParse(row['ph_dose_requested_at'] as String)
            : null,
      );

  @override
  Stream<ActuatorState> watchActuators(String podId) async* {
    yield stateOf(await _read(podId));
    yield* _source.deviceChanges(podId).map(stateOf);
  }

  @override
  Future<void> setPump(String podId, {required bool on}) =>
      _send(podId, {'pump_on': on});

  @override
  Future<void> setLight(String podId, {required bool on, int? brightness}) =>
      _send(podId, {
        'light_on': on,
        if (brightness != null) 'light_brightness': brightness.clamp(0, 100),
      });

  @override
  Future<void> setMist(String podId, {required bool on}) =>
      _send(podId, {'mist_on': on});

  @override
  Future<PhDoseResult> dosePhDown(String podId) async {
    await _send(podId, {'ph_dose_requested_at': _now()});
    return PhDoseResult.applied;
  }

  @override
  Future<void> markRefilled(String podId) =>
      _send(podId, {'refill_requested_at': _now()});

  String _now() => _clock().toUtc().toIso8601String();

  Future<Map<String, dynamic>> _read(String podId) async {
    try {
      return await _source.fetchDevice(podId);
    } catch (e, s) {
      _log.error('Could not read pod controls', e, s);
      throw NetworkFailure(
        'Could not reach the pod. Check your connection.',
        e,
      );
    }
  }

  /// Writes [values] if the pod is online, else throws a [DeviceFailure].
  Future<void> _send(String podId, Map<String, dynamic> values) async {
    final row = await _read(podId);
    if (row['is_online'] != true) {
      throw const DeviceFailure(
        'The pod is offline. Check its Wi-Fi and try again.',
      );
    }
    try {
      await _source.updateDevice(podId, values);
    } catch (e, s) {
      _log.error('Pod command failed', e, s);
      throw NetworkFailure('The command did not reach the pod. Try again.', e);
    }
  }
}
