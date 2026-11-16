import 'package:aquagrow_mobile/app/shell/notification_setup.dart';
import 'package:aquagrow_mobile/app/shell/offline_banner.dart';
import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
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
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.eco_outlined),
      selectedIcon: Icon(Icons.eco),
      label: 'Crops',
    ),
    NavigationDestination(
      icon: Icon(Icons.insights_outlined),
      selectedIcon: Icon(Icons.insights),
      label: 'Insights',
    ),
    NavigationDestination(
      icon: Icon(Icons.spa_outlined),
      selectedIcon: Icon(Icons.spa),
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
    final c = context.ag;
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
      // Minimal UI: a floating white pill; only the current tab shows its
      // label, on a lime indicator.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AgSpace.s16,
            0,
            AgSpace.s16,
            AgSpace.s8,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AgRadius.all(AgRadius.pill),
              boxShadow: [
                BoxShadow(
                  color: c.text.withValues(alpha: 0.1),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: AgRadius.all(AgRadius.pill),
              child: NavigationBar(
                height: 64,
                backgroundColor: c.background,
                indicatorColor: c.brand,
                labelBehavior:
                    NavigationDestinationLabelBehavior.onlyShowSelected,
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: _onTap,
                destinations: destinations,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
