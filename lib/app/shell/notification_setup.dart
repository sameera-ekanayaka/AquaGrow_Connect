import 'package:aquagrow_mobile/app/router/app_router.dart';
import 'package:aquagrow_mobile/app/router/app_routes.dart';
import 'package:aquagrow_mobile/features/alerts/application/notification_permission.dart';
import 'package:aquagrow_mobile/features/alerts/application/notification_service.dart';
import 'package:aquagrow_mobile/features/onboarding/application/onboarding_store.dart';
import 'package:aquagrow_mobile/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Starts notifications once the signed-in shell is on screen.
///
/// - Tapping a notification opens the Alerts screen.
/// - On first launch after sign-in, explains why and then asks for the
///   notification permission (Android 13+). It never asks twice.
class NotificationSetup extends ConsumerStatefulWidget {
  /// Wraps [child], which is shown unchanged.
  const NotificationSetup({required this.child, super.key});

  /// The shell content.
  final Widget child;

  /// Title of the explanation dialog shown before the system prompt.
  static const explainTitle = 'Get notified when your plants need you';

  @override
  ConsumerState<NotificationSetup> createState() => _NotificationSetupState();
}

class _NotificationSetupState extends ConsumerState<NotificationSetup> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  ProviderSubscription<bool>? _restoredSub;

  Future<void> _start() async {
    if (!mounted) return;
    final router = GoRouter.of(context);
    await ref.read(notificationServiceProvider).init(
          onTap: () => router.push(AppRoutes.alerts),
        );
    if (!mounted) return;
    // The shell is built under the splash before the session is restored,
    // and the router may then send the user to onboarding or login. Only
    // ask once the user is really on the signed-in shell.
    if (ref.read(authSessionProvider).isRestored) {
      await _askIfSignedIn();
    } else {
      _restoredSub = ref.listenManual<bool>(
        authSessionProvider.select((s) => s.isRestored),
        (_, restored) {
          if (!restored) return;
          _restoredSub?.close();
          _restoredSub = null;
          // Let the router redirect first, so a shell that is leaving is
          // no longer mounted.
          WidgetsBinding.instance.addPostFrameCallback((_) => _askIfSignedIn());
        },
      );
    }
  }

  Future<void> _askIfSignedIn() async {
    if (!mounted) return;
    final signedIn = ref.read(authSessionProvider).isSignedIn;
    final onboardingSeen = ref.read(onboardingStoreProvider).isSeen;
    if (!signedIn || !onboardingSeen) return;
    await ref.read(notificationPermissionFlowProvider).run(explain: _explain);
  }

  @override
  void dispose() {
    _restoredSub?.close();
    super.dispose();
  }

  Future<bool> _explain() async {
    if (!mounted) return false;
    return showConfirmDialog(
      context,
      title: NotificationSetup.explainTitle,
      message:
          'AquaGrow sends a notification when a pod reading turns critical, '
          'for example a pH crash or a nearly empty tank. You can turn this off '
          'at any time in your phone settings.',
      confirmLabel: 'Allow',
      cancelLabel: 'Not now',
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
