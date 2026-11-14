import 'dart:async';

import 'package:aquagrow_mobile/app/shell/offline_banner.dart';
import 'package:aquagrow_mobile/core/config/app_config.dart';
import 'package:aquagrow_mobile/core/constants/app_constants.dart';
import 'package:aquagrow_mobile/core/logging/app_logger.dart';
import 'package:aquagrow_mobile/core/models/pod.dart';
import 'package:aquagrow_mobile/core/models/sensor_reading.dart';
import 'package:aquagrow_mobile/core/network/supabase_client.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/data/supabase/supabase_telemetry_uploader.dart';
import 'package:aquagrow_mobile/features/storage/local_cache_service.dart';
import 'package:aquagrow_mobile/features/sync/application/logging_telemetry_uploader.dart';
import 'package:aquagrow_mobile/features/sync/application/sync_service.dart';
import 'package:aquagrow_mobile/features/sync/data/hive_sync_queue.dart';
import 'package:aquagrow_mobile/features/sync/domain/sync_queue.dart';
import 'package:aquagrow_mobile/features/sync/domain/telemetry_uploader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

const _log = AppLogger('sync');

/// Where queued readings are kept: the Hive `offline_sync_queue` box opened
/// in `bootstrap.dart`, or memory if Hive did not open (and in tests).
final syncQueueProvider = Provider<SyncQueue>((ref) {
  if (Hive.isBoxOpen(AppConstants.offlineQueueBoxKey)) {
    return HiveSyncQueue(
      Hive.box<String>(AppConstants.offlineQueueBoxKey),
      capacity: AppConstants.maxOfflineQueueItems,
    );
  }
  _log.warning('Sync queue box not open, keeping the queue in memory');
  return InMemorySyncQueue(capacity: AppConstants.maxOfflineQueueItems);
});

/// Saves one reading to the 72-hour local cache. Does nothing if the Hive
/// cache box is not open, so tests never touch a real plugin.
final readingCacheProvider =
    Provider<Future<void> Function(SensorReading reading)>((ref) {
  if (!Hive.isBoxOpen(AppConstants.telemetryOfflineCacheBoxKey)) {
    return (_) async {};
  }
  return ref.watch(localCacheServiceProvider).cacheTelemetry;
});

/// Supabase in live mode; otherwise the uploader that only logs.
final telemetryUploaderProvider = Provider<TelemetryUploader>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.dataMode == DataMode.live && SupabaseManager.isConfigured) {
    return SupabaseTelemetryUploader(SupabaseManager.client);
  }
  return const LoggingTelemetryUploader();
});

/// The one running [SyncService]. It follows every pod's readings and the
/// connection state, and its [SyncStatus] drives the Profile "Last synced" row.
final syncServiceProvider =
    StateNotifierProvider<SyncService, SyncStatus>((ref) {
  final service = SyncService(
    queue: ref.watch(syncQueueProvider),
    uploader: ref.watch(telemetryUploaderProvider),
    cache: ref.watch(readingCacheProvider),
  );
  final telemetry = ref.watch(telemetryRepositoryProvider);

  ref.listen<AsyncValue<List<Pod>>>(
    podsProvider,
    (_, next) => next.whenData((pods) => service.watchPods(pods, telemetry)),
    fireImmediately: true,
  );
  ref.listen<AsyncValue<bool>>(
    isOfflineProvider,
    (_, next) => next.whenData((offline) {
      unawaited(service.setOffline(offline));
    }),
    fireImmediately: true,
  );
  return service;
});

/// Emits how many readings each sync uploaded, for the "readings synced"
/// SnackBar.
final syncedCountsProvider = StreamProvider<int>((ref) {
  return ref.watch(syncServiceProvider.notifier).syncedCounts;
});

/// The current time, refreshed every 30 seconds so "2 min ago" stays true.
/// Tests override it with a fixed time.
final syncClockProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(seconds: 30), (_) => DateTime.now());
});
