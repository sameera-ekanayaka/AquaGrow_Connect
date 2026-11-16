import 'package:aquagrow_mobile/core/logging/app_logger.dart';
import 'package:aquagrow_mobile/core/models/pod_alert.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _log = AppLogger('notifications');

/// Shows system notifications for alerts.
///
/// The app talks to this interface only, so tests use a fake and never touch
/// the real plugin.
abstract interface class NotificationService {
  /// Sets up the plugin and the Android channel. [onTap] runs when the user
  /// taps one of our notifications, including one that launched the app.
  Future<void> init({required void Function() onTap});

  /// Whether the user currently allows notifications from this app.
  Future<bool> areEnabled();

  /// Shows the system permission prompt (Android 13+). Returns true if allowed.
  Future<bool> requestPermission();

  /// Shows [alert] as a system notification.
  Future<void> showAlert(PodAlert alert);
}

/// [NotificationService] built on `flutter_local_notifications` (Android).
class LocalNotificationService implements NotificationService {
  /// Creates the service. Pass a [plugin] only to replace the default one.
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// Android channel id for pod alerts.
  static const channelId = 'pod_alerts';

  /// Channel name shown in the phone's notification settings.
  static const channelName = 'Pod alerts';

  static const _channelDescription =
      'Critical readings from your AquaGrow pods';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  IOSFlutterLocalNotificationsPlugin? get _ios =>
      _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

  @override
  Future<void> init({required void Function() onTap}) async {
    if (_ready) return;
    try {
      await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          // iOS asks later, from the same prompt as Android (see
          // NotificationPermission), not on the first launch.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (_) => onTap(),
      );
      await _android?.createNotificationChannel(
        const AndroidNotificationChannel(
          channelId,
          channelName,
          description: _channelDescription,
          importance: Importance.high,
        ),
      );
      _ready = true;

      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) onTap();
    } catch (e, st) {
      _log.error('Notifications could not start', e, st);
    }
  }

  @override
  Future<bool> areEnabled() async {
    try {
      final android = _android;
      if (android != null) {
        return await android.areNotificationsEnabled() ?? false;
      }
      return (await _ios?.checkPermissions())?.isEnabled ?? false;
    } catch (e, st) {
      _log.error('Could not read notification permission', e, st);
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      final android = _android;
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }
      return await _ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    } catch (e, st) {
      _log.error('Notification permission request failed', e, st);
      return false;
    }
  }

  @override
  Future<void> showAlert(PodAlert alert) async {
    if (!_ready) {
      _log.warning('Notification skipped, service not started: ${alert.title}');
      return;
    }
    try {
      await _plugin.show(
        notificationIdFor(alert.id),
        alert.title,
        alert.message,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
          ),
        ),
        payload: alert.id,
      );
    } catch (e, st) {
      _log.error('Could not show notification', e, st);
    }
  }

  /// A stable, positive 31-bit notification id for an alert id.
  static int notificationIdFor(String alertId) {
    // FNV-1a: the same alert id always gives the same notification id.
    var hash = 0x811c9dc5;
    for (final unit in alertId.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
    }
    return hash & 0x7fffffff;
  }
}

/// The app's notification service. Tests override it with a fake.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return LocalNotificationService();
});
