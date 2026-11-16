import 'package:aquagrow_mobile/app/shell/notification_setup.dart';
import 'package:aquagrow_mobile/app/shell/offline_banner.dart';
import 'package:aquagrow_mobile/app/shell/pill_nav_bar.dart';
import 'package:aquagrow_mobile/features/alerts/application/alert_engine.dart';
import 'package:aquagrow_mobile/features/sync/presentation/sync_listener.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The bottom navigation bar with the four main tabs from Figma.
///
/// Each tab keeps its own navigation stack and scroll position
/// (go_router `StatefulShellRoute.indexedStack`), so switching tabs never
/// loses what the user was doing.
///
/// The shell also keeps the alert engine running while the user is signed in,
/// starts notifications ([NotificationSetup]) and keeps offline sync running
/// ([SyncListener]).
class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  /// Tab order must match the branches in `app_router.dart`.
  static const destinations = [
    PillNavItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Home',
    ),
    PillNavItem(
      icon: Icons.eco_outlined,
      selectedIcon: Icons.eco,
      label: 'Crops',
    ),
    PillNavItem(
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights,
      label: 'Insights',
    ),
    PillNavItem(
      icon: Icons.spa_outlined,
      selectedIcon: Icons.spa,
      label: 'Care',
    ),
  ];

  void _onTap(int index) {
    // Tapping the current tab again returns it to its first screen.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Starts the alert engine once and keeps it alive while the shell is shown.
    ref.watch(alertEngineProvider);
    return Scaffold(
      body: SyncListener(
        child: NotificationSetup(
          child: Column(
            children: [
              const OfflineBanner(),
              Expanded(child: navigationShell),
            ],
          ),
        ),
      ),
      bottomNavigationBar: PillNavBar(
        items: destinations,
        selectedIndex: navigationShell.currentIndex,
        onSelected: _onTap,
      ),
    );
  }
}
