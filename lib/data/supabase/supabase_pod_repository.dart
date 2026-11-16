import 'dart:async';

import 'package:aquagrow_mobile/core/errors/app_failure.dart';
import 'package:aquagrow_mobile/core/interfaces/i_pod_repository.dart';
import 'package:aquagrow_mobile/core/logging/app_logger.dart';
import 'package:aquagrow_mobile/core/models/new_pod.dart';
import 'package:aquagrow_mobile/core/models/pod.dart';
import 'package:aquagrow_mobile/data/supabase/supabase_rows.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _log = AppLogger('supabase');

/// Where device rows come from. An interface so tests can use a fake.
abstract interface class DeviceSource {
  /// The signed-in user's `devices` rows. Row Level Security returns only
  /// devices they own.
  Future<List<Map<String, dynamic>>> fetchDevices();

  /// Emits whenever a device row changes.
  Stream<void> changes();

  /// Inserts a `devices` row owned by the signed-in user and returns it,
  /// read back with [devicesSelect].
  Future<Map<String, dynamic>> insertDevice(Map<String, dynamic> values);
}

/// [DeviceSource] backed by Supabase (REST for reads, realtime for changes).
class SupabaseDeviceSource implements DeviceSource {
  /// Reads devices through [client].
  SupabaseDeviceSource(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Map<String, dynamic>>> fetchDevices() =>
      _client.from('devices').select(devicesSelect).order('created_at');

  @override
  Future<Map<String, dynamic>> insertDevice(Map<String, dynamic> values) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthFailure('Sign in again to add a pod.');
    }
    return _client
        .from('devices')
        .insert({...values, 'owner_id': user.id})
        .select(devicesSelect)
        .single();
  }

  @override
  Stream<void> changes() {
    late final RealtimeChannel channel;
    late final StreamController<void> controller;
    controller = StreamController<void>(
      onListen: () {
        channel = _client
            .channel('devices-changes')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'devices',
              callback: (_) => controller.add(null),
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

/// The user's pods from the Supabase `devices` table (live mode).
///
/// Each pod carries its active crop batch and recipe. The list is read again
/// whenever a device changes, for example when a pod goes offline.
class SupabasePodRepository implements IPodRepository {
  /// Reads pods from [source].
  SupabasePodRepository(this._source);

  final DeviceSource _source;

  @override
  Future<List<Pod>> getPods() async {
    try {
      final rows = await _source.fetchDevices();
      return rows.map(SupabaseRows.pod).toList(growable: false);
    } catch (e, s) {
      _log.error('Could not load pods', e, s);
      throw NetworkFailure(
        'Could not load your pods. Check your connection.',
        e,
      );
    }
  }

  /// The `devices` columns for a new pod. It starts offline: it goes live
  /// when the pod (or the 3D simulation) sends its first reading.
  static Map<String, dynamic> newDeviceRow(NewPod pod) => {
        'device_name': pod.name,
        'room': pod.room,
        'serial_number': pod.serialNumber,
        'system_type': pod.systemType.code,
        'is_online': false,
      };

  @override
  Future<Pod> addPod(NewPod pod) async {
    try {
      final row = await _source.insertDevice(newDeviceRow(pod));
      return SupabaseRows.pod(row);
    } on AppFailure {
      rethrow;
    } on PostgrestException catch (e, s) {
      _log.error('Could not add pod', e, s);
      // 23505: unique_violation on devices.serial_number.
      if (e.code == '23505') {
        throw const ValidationFailure(
            'This serial number is already registered.');
      }
      // 42501: Row Level Security refused the insert.
      if (e.code == '42501') {
        throw AuthFailure('Sign in again to add a pod.', cause: e);
      }
      throw NetworkFailure('Could not add the pod. Check your connection.', e);
    } catch (e, s) {
      _log.error('Could not add pod', e, s);
      throw NetworkFailure('Could not add the pod. Check your connection.', e);
    }
  }

  @override
  Stream<List<Pod>> watchPods() {
    late final StreamController<List<Pod>> controller;
    StreamSubscription<void>? changes;

    Future<void> load({required bool first}) async {
      try {
        final pods = await getPods();
        if (!controller.isClosed) controller.add(pods);
      } on AppFailure catch (e) {
        if (controller.isClosed) return;
        // The first load shows the error; later failures keep the last list.
        if (first) {
          controller.addError(e);
        } else {
          _log.warning('Pod refresh failed: ${e.message}');
        }
      }
    }

    controller = StreamController<List<Pod>>(
      onListen: () {
        unawaited(load(first: true));
        changes = _source.changes().listen((_) => load(first: false));
      },
      // Cancelling closes the realtime channel straight away.
      onCancel: () async {
        await changes?.cancel();
        await controller.close();
      },
    );
    return controller.stream;
  }
}
