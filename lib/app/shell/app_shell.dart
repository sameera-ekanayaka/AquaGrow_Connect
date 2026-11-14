import 'package:aquagrow_mobile/app/shell/offline_banner.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The bottom navigation bar with the four main tabs from Figma.
///
/// Each tab keeps its own navigation stack and scroll position
/// (go_router `StatefulShellRoute.indexedStack`), so switching tabs never
/// loses what the user was doing.
class AppShell extends StatelessWidget {
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
      icon: Icon(Icons.add_box_outlined),
      selectedIcon: Icon(Icons.add_box),
      label: 'Care',
    ),
  ];

  void _onTap(int index) {
    // Tapping the current tab again returns it to its first screen.
    navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        destinations: destinations,
      ),
    );
  }
}
