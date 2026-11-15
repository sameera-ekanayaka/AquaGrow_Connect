import 'package:aquagrow_mobile/core/constants/app_constants.dart';
import 'package:aquagrow_mobile/core/interfaces/i_local_data_eraser.dart';
import 'package:aquagrow_mobile/core/interfaces/i_preferences_store.dart';
import 'package:aquagrow_mobile/core/logging/app_logger.dart';
import 'package:hive/hive.dart';

const _log = AppLogger('privacy');

/// Clears the app's Hive boxes and its preferences.
class HiveLocalDataEraser implements ILocalDataEraser {
  /// Creates an eraser for [preferences] and the Hive boxes in [boxNames].
  HiveLocalDataEraser({
    required IPreferencesStore preferences,
    this.boxNames = defaultBoxNames,
  }) : _preferences = preferences;

  /// Every Hive box the app writes to, apart from preferences. All of them
  /// are opened as `Box<String>` (see `LocalCacheService`).
  static const defaultBoxNames = [
    AppConstants.telemetryOfflineCacheBoxKey,
    AppConstants.offlineQueueBoxKey,
  ];

  /// Names of the Hive boxes to clear. Boxes that are not open are skipped.
  final List<String> boxNames;

  final IPreferencesStore _preferences;

  @override
  Future<void> eraseAll() async {
    for (final name in boxNames) {
      if (Hive.isBoxOpen(name)) await Hive.box<String>(name).clear();
    }
    await _preferences.clear();
    _log.info('Local data deleted by the user');
  }
}
