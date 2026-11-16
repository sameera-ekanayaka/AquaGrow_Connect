import 'dart:async';

import 'package:aquagrow_mobile/core/errors/app_failure.dart';
import 'package:aquagrow_mobile/core/interfaces/i_pod_repository.dart';
import 'package:aquagrow_mobile/core/logging/app_logger.dart';
import 'package:aquagrow_mobile/core/models/crop_recipe.dart';
import 'package:aquagrow_mobile/core/models/new_pod.dart';
import 'package:aquagrow_mobile/core/models/pod.dart';
import 'package:aquagrow_mobile/data/supabase/realtime_topics.dart';
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

  /// The id of the `crop_recipes` row named [cropName], or null if none.
  Future<String?> recipeIdFor(String cropName);

  /// Inserts a `crop_batches` row.
  Future<void> insertBatch(Map<String, dynamic> values);

  /// Sets every ACTIVE batch of [deviceId] to HARVESTED.
  Future<void> harvestBatches(String deviceId);
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
  Future<String?> recipeIdFor(String cropName) async {
    final row = await _client
        .from('crop_recipes')
        .select('id')
        .eq('crop_name', cropName)
        .limit(1)
        .maybeSingle();
    return row?['id'] as String?;
  }

  @override
  Future<void> insertBatch(Map<String, dynamic> values) =>
      _client.from('crop_batches').insert(values);

  @override
  Future<void> harvestBatches(String deviceId) => _client
      .from('crop_batches')
      .update({'status': 'HARVESTED'})
      .eq('device_id', deviceId)
      .eq('status', 'ACTIVE');

  @override
  Stream<void> changes() {
    late final RealtimeChannel channel;
    late final StreamController<void> controller;
    controller = StreamController<void>(
      onListen: () {
        channel = _client
            .channel(RealtimeTopics.unique('devices-changes'))
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'devices',
              callback: (_) => controller.add(null),
            )
            // Planting and harvesting change the pod's crop.
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'crop_batches',
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
          'This serial number is already registered.',
        );
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

  /// The `crop_batches` columns for [recipe] planted in [podId] on [today].
  static Map<String, dynamic> newBatchRow(
    String podId,
    CropRecipe recipe,
    String? recipeId,
    DateTime today,
  ) =>
      {
        'device_id': podId,
        'recipe_id': recipeId,
        'custom_crop_name': recipe.cropName,
        'planted_date': _date(today),
        'expected_harvest_date':
            _date(today.add(Duration(days: recipe.durationDays))),
        'status': 'ACTIVE',
      };

  static String _date(DateTime d) =>
      d.toIso8601String().substring(0, 10); // yyyy-MM-dd

  @override
  Future<void> plantCrop(String podId, CropRecipe recipe) => _write(
        'Could not plant the crop. Check your connection.',
        () async {
          final recipeId = await _source.recipeIdFor(recipe.cropName);
          await _source.insertBatch(
            newBatchRow(podId, recipe, recipeId, DateTime.now()),
          );
        },
      );

  @override
  Future<void> harvest(String podId) => _write(
        'Could not save the harvest. Check your connection.',
        () => _source.harvestBatches(podId),
      );

  /// Runs [write], turning errors into [AppFailure]s with [message].
  Future<void> _write(String message, Future<void> Function() write) async {
    try {
      await write();
    } on AppFailure {
      rethrow;
    } on PostgrestException catch (e, s) {
      _log.error(message, e, s);
      if (e.code == '42501') {
        throw AuthFailure('Sign in again and try once more.', cause: e);
      }
      throw NetworkFailure(message, e);
    } catch (e, s) {
      _log.error(message, e, s);
      throw NetworkFailure(message, e);
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
