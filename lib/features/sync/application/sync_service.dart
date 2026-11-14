import 'dart:async';

import 'package:aquagrow_mobile/core/interfaces/i_telemetry_repository.dart';
import 'package:aquagrow_mobile/core/logging/app_logger.dart';
import 'package:aquagrow_mobile/core/models/pod.dart';
import 'package:aquagrow_mobile/core/models/sensor_reading.dart';
import 'package:aquagrow_mobile/features/sync/domain/sync_queue.dart';
import 'package:aquagrow_mobile/features/sync/domain/telemetry_uploader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _log = AppLogger('sync');

/// What the sync service has done so far. Shown on the Profile screen.
class SyncStatus {
  /// Creates a status.
  const SyncStatus({
    this.lastSyncedAt,
    this.lastSyncedCount = 0,
    this.pending = 0,
    this.offline = false,
  });

  /// When the queue was last emptied, or null if it never was.
  final DateTime? lastSyncedAt;

  /// How many readings that last sync uploaded.
  final int lastSyncedCount;

  /// Readings waiting to be uploaded.
  final int pending;

  /// True while the phone has no connection.
  final bool offline;

  /// A copy with the given fields changed.
  SyncStatus copyWith({
    DateTime? lastSyncedAt,
    int? lastSyncedCount,
    int? pending,
    bool? offline,
  }) {
    return SyncStatus(
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastSyncedCount: lastSyncedCount ?? this.lastSyncedCount,
      pending: pending ?? this.pending,
      offline: offline ?? this.offline,
    );
  }
}

/// Keeps readings safe while the phone is offline (lecture 1).
///
/// 1. Every reading is saved to the local cache (72-hour window), so charts
///    and tiles still have data offline.
/// 2. While offline, each reading is also added to the [SyncQueue].
/// 3. When the connection returns, the queue is uploaded in batches of
///    [batchSize] and cleared. If a batch fails, it stays queued and the
///    next reconnect tries again.
///
/// **Conflict rule:** readings are append-only. The server keeps every row
/// and never updates one, so there is nothing to merge. A reading that is
/// uploaded twice (for example after a retry) is ignored by its reading id.
class SyncService extends StateNotifier<SyncStatus> {
  /// Creates the service. [cache] saves one reading locally; [clock] gives
  /// the time (tests pass a fixed one).
  SyncService({
    required SyncQueue queue,
    required TelemetryUploader uploader,
    required Future<void> Function(SensorReading reading) cache,
    DateTime Function()? clock,
    this.batchSize = 50,
  })  : _queue = queue,
        _uploader = uploader,
        _cache = cache,
        _clock = clock ?? DateTime.now,
        super(SyncStatus(pending: queue.length));

  /// Readings sent per upload request.
  final int batchSize;

  final SyncQueue _queue;
  final TelemetryUploader _uploader;
  final Future<void> Function(SensorReading reading) _cache;
  final DateTime Function() _clock;

  final _synced = StreamController<int>.broadcast();
  final Map<String, StreamSubscription<SensorReading>> _subscriptions = {};
  bool? _offline;
  Future<int>? _flushing;

  /// Emits the number of readings uploaded, each time a sync uploads any.
  /// The app shows "Back online · N readings synced" from this.
  Stream<int> get syncedCounts => _synced.stream;

  /// Starts saving readings from every pod in [pods] and stops for removed ones.
  void watchPods(List<Pod> pods, ITelemetryRepository telemetry) {
    final ids = {for (final pod in pods) pod.id};
    for (final id in _subscriptions.keys.toList()) {
      if (!ids.contains(id)) _subscriptions.remove(id)?.cancel();
    }
    for (final pod in pods) {
      _subscriptions.putIfAbsent(
        pod.id,
        () => telemetry.watchReadings(pod.id).listen(
              onReading,
              onError: (Object e, StackTrace s) =>
                  _log.error('Reading stream failed for ${pod.id}', e, s),
            ),
      );
    }
  }

  /// Saves [reading] locally and, while offline, queues it for upload.
  Future<void> onReading(SensorReading reading) async {
    try {
      await _cache(reading);
    } catch (e, s) {
      // A full or broken cache must never stop the queue or the app.
      _log.error('Could not cache a reading', e, s);
    }
    if (_offline ?? false) {
      await _queue.add(reading);
      if (mounted) state = state.copyWith(pending: _queue.length);
    }
  }

  /// Tells the service whether the phone is [offline]. Coming back online
  /// (or starting online with readings left from last time) uploads the queue.
  Future<void> setOffline(bool offline) async {
    final wasOffline = _offline ?? true;
    _offline = offline;
    if (mounted) state = state.copyWith(offline: offline);
    if (!offline && wasOffline && _queue.length > 0) {
      await flush();
    }
  }

  /// Uploads the whole queue in batches and returns how many readings went up.
  /// Stops at the first failed batch and keeps it queued for the next try.
  Future<int> flush() => _flushing ??= _flush().whenComplete(() {
        _flushing = null;
      });

  Future<int> _flush() async {
    var uploaded = 0;
    var failed = false;
    while (_queue.length > 0) {
      final batch = _queue.peek(batchSize);
      try {
        await _uploader.upload(batch);
      } catch (e, s) {
        _log.error('Upload failed, keeping ${_queue.length} readings', e, s);
        failed = true;
        break;
      }
      await _queue.remove(batch.map((r) => r.id));
      uploaded += batch.length;
    }

    if (!mounted) return uploaded;
    state = state.copyWith(
      pending: _queue.length,
      lastSyncedAt: failed ? null : _clock(),
      lastSyncedCount: failed ? null : uploaded,
    );
    if (uploaded > 0) {
      _log.info('Synced $uploaded readings');
      _synced.add(uploaded);
    }
    return uploaded;
  }

  @override
  void dispose() {
    for (final sub in _subscriptions.values) {
      unawaited(sub.cancel());
    }
    _subscriptions.clear();
    unawaited(_synced.close());
    super.dispose();
  }
}
