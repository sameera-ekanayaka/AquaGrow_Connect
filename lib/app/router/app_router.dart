import 'package:aquagrow_mobile/app/router/app_routes.dart';
import 'package:aquagrow_mobile/app/router/auth_session.dart';
import 'package:aquagrow_mobile/app/shell/app_shell.dart';
import 'package:aquagrow_mobile/features/alerts/presentation/alerts_screen.dart';
import 'package:aquagrow_mobile/features/auth/presentation/auth_providers.dart';
import 'package:aquagrow_mobile/features/auth/presentation/login_screen.dart';
import 'package:aquagrow_mobile/features/auth/presentation/profile_screen.dart';
import 'package:aquagrow_mobile/features/auth/presentation/register_screen.dart';
import 'package:aquagrow_mobile/features/care/presentation/care_screen.dart';
import 'package:aquagrow_mobile/features/crops/presentation/crop_detail_screen.dart';
import 'package:aquagrow_mobile/features/crops/presentation/crops_screen.dart';
import 'package:aquagrow_mobile/features/crops/presentation/harvest_passport_screen.dart';
import 'package:aquagrow_mobile/features/dashboard/presentation/home_screen.dart';
import 'package:aquagrow_mobile/features/insights/presentation/insights_screen.dart';
import 'package:aquagrow_mobile/features/location/presentation/hydro_map_screen.dart';
import 'package:aquagrow_mobile/features/location/presentation/microclimate_screen.dart';
import 'package:aquagrow_mobile/features/settings/presentation/settings_screen.dart';
import 'package:aquagrow_mobile/features/simulator/presentation/simulator_panel_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Signed-in state the router listens to.
final authSessionProvider = ChangeNotifierProvider<AuthSession>((ref) {
  return AuthSession(ref.watch(authRepositoryProvider));
});

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// The app's single router.
///
/// HOW TO ADD A SCREEN:
/// 1. Add its path to `AppRoutes`.
/// 2. Add a `GoRoute` below: inside a tab's branch if the bottom bar should
///    stay visible, or at the top level (with `parentNavigatorKey: _rootKey`
///    implied) if it should cover the bar.
/// 3. Navigate with `context.push(AppRoutes.x)` or `context.go(AppRoutes.x)`.
final routerProvider = Provider<GoRouter>((ref) {
  // read, not watch: the router must be built once. It re-checks the
  // redirect itself whenever the session notifies (refreshListenable).
  final session = ref.read(authSessionProvider);

  final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AppRoutes.home,
    refreshListenable: session,
    redirect: (context, state) => authRedirect(
      isRestored: session.isRestored,
      isSignedIn: session.isSignedIn,
      location: state.matchedLocation,
    ),
    routes: [
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.register, builder: (_, __) => const RegisterScreen()),

      // Bottom-navigation tabs. Order must match AppShell.destinations.
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.home, builder: (_, __) => const HomeScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.crops,
                builder: (_, __) => const CropsScreen(),
                routes: [
                  GoRoute(
                    path: ':podId',
                    parentNavigatorKey: _rootKey,
                    builder: (_, state) =>
                        CropDetailScreen(podId: state.pathParameters['podId']!),
                    routes: [
                      GoRoute(
                        path: 'passport',
                        parentNavigatorKey: _rootKey,
                        builder: (_, state) => HarvestPassportScreen(
                          podId: state.pathParameters['podId']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.insights,
                builder: (_, __) => const InsightsScreen(),
                routes: [
                  GoRoute(
                    path: 'microclimate',
                    parentNavigatorKey: _rootKey,
                    builder: (_, __) => const MicroclimateScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.care,
                builder: (_, __) => const CareScreen(),
                routes: [
                  GoRoute(
                    path: 'suppliers',
                    parentNavigatorKey: _rootKey,
                    builder: (_, __) => const HydroMapScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // Full-screen pages that cover the bottom bar.
      GoRoute(path: AppRoutes.alerts, builder: (_, __) => const AlertsScreen()),
      GoRoute(path: AppRoutes.profile, builder: (_, __) => const ProfileScreen()),
      GoRoute(path: AppRoutes.simulator, builder: (_, __) => const SimulatorPanelScreen()),
      GoRoute(path: AppRoutes.settings, builder: (_, __) => const SettingsScreen()),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});

/// Where to send the user, or null to stay. Pure function, unit tested.
///
/// - Signed out: only the login and register screens are reachable.
/// - Signed in: login and register bounce to Home.
/// - While the saved session is still loading, stay put.
String? authRedirect({
  required bool isRestored,
  required bool isSignedIn,
  required String location,
}) {
  if (!isRestored) return null;
  final isPublic = AppRoutes.publicRoutes.contains(location);
  if (!isSignedIn && !isPublic) return AppRoutes.login;
  if (isSignedIn && isPublic) return AppRoutes.home;
  return null;
}
