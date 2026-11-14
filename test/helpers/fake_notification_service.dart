import 'package:aquagrow_mobile/core/models/pod_alert.dart';
import 'package:aquagrow_mobile/features/alerts/application/notification_service.dart';

/// A [NotificationService] that records calls instead of using the plugin.
class FakeNotificationService implements NotificationService {
  /// Creates the fake. [enabled] is whether notifications start allowed;
  /// [grant] is what the system prompt answers.
  FakeNotificationService({this.enabled = true, this.grant = true});

  /// Whether notifications are allowed right now.
  bool enabled;

  /// What [requestPermission] answers.
  bool grant;

  /// Every alert shown, oldest first.
  final List<PodAlert> shown = [];

  /// How many times the system prompt was shown.
  int permissionRequests = 0;

  /// The tap handler passed to [init], or null before [init].
  void Function()? onTap;

  /// Pretends the user tapped a notification.
  void tap() => onTap?.call();

  @override
  Future<void> init({required void Function() onTap}) async =>
      this.onTap = onTap;

  @override
  Future<bool> areEnabled() async => enabled;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    enabled = grant;
    return grant;
  }

  @override
  Future<void> showAlert(PodAlert alert) async => shown.add(alert);
}
