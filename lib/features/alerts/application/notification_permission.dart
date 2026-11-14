import 'package:aquagrow_mobile/core/interfaces/i_preferences_store.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/features/alerts/application/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Asks for the notification permission once, after explaining why.
///
/// - If notifications are already allowed (for example Android 12 and older),
///   nothing is shown.
/// - Otherwise the app first explains why (`explain`), and only if the user
///   agrees shows the system prompt.
/// - Either way it is asked only once; the user can change it later in the
///   phone's settings.
class NotificationPermissionFlow {
  /// Creates the flow from the notification [service] and saved [preferences].
  NotificationPermissionFlow({
    required NotificationService service,
    required IPreferencesStore preferences,
  })  : _service = service,
        _preferences = preferences;

  /// Preference key that records the question was already asked.
  static const askedKey = 'notifications_permission_asked';

  final NotificationService _service;
  final IPreferencesStore _preferences;

  /// Runs the flow. [explain] shows the reason and returns true if the user
  /// wants notifications. Returns true if notifications end up allowed.
  Future<bool> run({required Future<bool> Function() explain}) async {
    if (await _service.areEnabled()) return true;
    if (_preferences.getBool(askedKey)) return false;

    await _preferences.setBool(askedKey, value: true);
    if (!await explain()) return false;
    return _service.requestPermission();
  }
}

/// The permission flow wired to the app's service and preferences.
final notificationPermissionFlowProvider =
    Provider<NotificationPermissionFlow>((ref) {
  return NotificationPermissionFlow(
    service: ref.watch(notificationServiceProvider),
    preferences: ref.watch(preferencesStoreProvider),
  );
});
