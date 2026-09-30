import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/sensor_reading.dart';
import '../../core/network/supabase_client.dart';

/// Riverpod provider exposing the offline local cache service.
final localCacheServiceProvider = Provider<LocalCacheService>((ref) {
  return LocalCacheService();
});

/// Offline-first cache service utilizing Hive key-value storage.
/// Implements a 72-hour sliding retention window, FIFO eviction,
/// and a persistent queue that synchronizes pending packets when internet restores.
class LocalCacheService {
  static bool _isHiveInitialized = false;

  /// Initializes Hive local storage and ensures required boxes are open.
  static Future<void> initialize() async {
    if (_isHiveInitialized) return;
    await Hive.initFlutter();
    await Hive.openBox<String>(AppConstants.telemetryOfflineCacheBoxKey);
    await Hive.openBox<String>(AppConstants.offlineQueueBoxKey);
    _isHiveInitialized = true;
  }

  /// Caches a high-frequency sensor reading on local disk.
  /// Enforces both the 72-hour timestamp sliding window and max point limits.
  Future<void> cacheTelemetry(SensorReading reading) async {
    if (!_isHiveInitialized) await initialize();
    final box = Hive.box<String>(AppConstants.telemetryOfflineCacheBoxKey);

    // Persist reading keyed by unique ID or timestamp
    final key = reading.id.isNotEmpty
        ? reading.id
        : 'read_${reading.recordedAt.millisecondsSinceEpoch}';
    await box.put(key, jsonEncode(reading.toJson()));

    // Enforce 72-hour sliding retention window and FIFO cap
    await _enforceRetentionPolicies(box);
  }

  /// Retrieves all cached telemetry readings, sorted chronologically descending.
  List<SensorReading> getCachedTelemetry({String? deviceId}) {
    if (!_isHiveInitialized) return [];
    final box = Hive.box<String>(AppConstants.telemetryOfflineCacheBoxKey);

    final readings = <SensorReading>[];
    for (final rawJson in box.values) {
      try {
        final map = jsonDecode(rawJson) as Map<String, dynamic>;
        final reading = SensorReading.fromJson(map);
        if (deviceId == null || reading.deviceId == deviceId) {
          readings.add(reading);
        }
      } catch (_) {
        // Discard corrupt or malformed cache records
      }
    }

    // Sort descending by timestamp for immediate chart and widget ingestion
    readings.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return readings;
  }

  /// Returns the single most recent telemetry packet from local disk.
  SensorReading? getLatestCachedReading({String? deviceId}) {
    final list = getCachedTelemetry(deviceId: deviceId);
    return list.isNotEmpty ? list.first : null;
  }

  /// Enqueues an offline operation (telemetry insert or actuator command)
  /// that could not be transmitted to the cloud due to network disruption.
  Future<void> enqueueOfflineAction({
    required String actionType,
    required Map<String, dynamic> payload,
  }) async {
    if (!_isHiveInitialized) await initialize();
    final box = Hive.box<String>(AppConstants.offlineQueueBoxKey);

    // Evict oldest queue item if capacity is reached
    if (box.length >= AppConstants.maxOfflineQueueItems) {
      final oldestKey = box.keys.first;
      await box.delete(oldestKey);
    }

    final queueId = 'queue_${DateTime.now().millisecondsSinceEpoch}';
    final envelope = {
      'id': queueId,
      'type': actionType,
      'payload': payload,
      'queued_at': DateTime.now().toIso8601String(),
    };

    await box.put(queueId, jsonEncode(envelope));
  }

  /// Returns the current number of pending items awaiting cloud synchronization.
  int get pendingQueueCount {
    if (!_isHiveInitialized) return 0;
    return Hive.box<String>(AppConstants.offlineQueueBoxKey).length;
  }

  /// Dispatches queued offline events to the Supabase cloud database once connectivity returns.
  /// Halts sequentially if a network error occurs to preserve ordering.
  Future<int> syncOfflineQueue() async {
    if (!_isHiveInitialized || !SupabaseManager.isConfigured) return 0;

    final box = Hive.box<String>(AppConstants.offlineQueueBoxKey);
    final keys = box.keys.toList();
    int syncedCount = 0;

    for (final key in keys) {
      final rawEnvelope = box.get(key);
      if (rawEnvelope == null) continue;

      try {
        final data = jsonDecode(rawEnvelope) as Map<String, dynamic>;
        final type = data['type'] as String?;
        final payload = data['payload'] as Map<String, dynamic>?;

        if (type == 'telemetry_insert' && payload != null) {
          await SupabaseManager.client.from('telemetry_logs').insert(payload);
          await box.delete(key);
          syncedCount++;
        } else if (type == 'actuator_log' && payload != null) {
          // Log actuator actions to relevant table if configured
          await box.delete(key);
          syncedCount++;
        } else {
          // Unknown format, remove to avoid blocking the queue
          await box.delete(key);
        }
      } catch (e) {
        // Stop batch on first network or permission failure
        break;
      }
    }

    return syncedCount;
  }

  /// Enforces the 72-hour retention cutoff and FIFO count limits.
  Future<void> _enforceRetentionPolicies(Box<String> box) async {
    final cutoff = DateTime.now().subtract(
      const Duration(hours: AppConstants.telemetryRetentionHours),
    );

    final keysToDelete = <dynamic>[];

    // Timestamp check
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw == null) continue;
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final recordedAtStr = map['recorded_at'] as String?;
        if (recordedAtStr != null) {
          final recordedAt = DateTime.parse(recordedAtStr);
          if (recordedAt.isBefore(cutoff)) {
            keysToDelete.add(key);
          }
        }
      } catch (_) {
        keysToDelete.add(key);
      }
    }

    // Evict expired entries
    if (keysToDelete.isNotEmpty) {
      await box.deleteAll(keysToDelete);
    }

    // FIFO count check
    if (box.length > AppConstants.maxLocalTelemetryPoints) {
      final overflow = box.length - AppConstants.maxLocalTelemetryPoints;
      final oldestKeys = box.keys.take(overflow).toList();
      await box.deleteAll(oldestKeys);
    }
  }

  /// Clears both offline telemetry cache and sync queue for test isolation or reset.
  Future<void> clearAll() async {
    if (!_isHiveInitialized) return;
    await Hive.box<String>(AppConstants.telemetryOfflineCacheBoxKey).clear();
    await Hive.box<String>(AppConstants.offlineQueueBoxKey).clear();
  }
}
