import 'package:aquagrow_mobile/app/router/app_router.dart';
import 'package:aquagrow_mobile/core/theme/app_theme.dart';
import 'package:aquagrow_mobile/features/auth/presentation/app_lock_gate.dart';
import 'package:aquagrow_mobile/features/onboarding/presentation/splash_screen.dart';
import 'package:aquagrow_mobile/features/settings/application/theme_mode_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Root widget: theme and router. Covers the app with the splash screen until
/// the saved sign-in session is restored, so the wrong screen never flashes,
/// and with the lock screen while the optional app lock is locked.
class AquaGrowApp extends ConsumerWidget {
  const AquaGrowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restored = ref.watch(authSessionProvider.select((s) => s.isRestored));
    final signedIn = ref.watch(authSessionProvider.select((s) => s.isSignedIn));
    return MaterialApp.router(
      title: 'AquaGrow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
      // The app builds underneath from the first frame, so screens start
      // loading straight away; the splash only covers it until the saved
      // session is restored.
      // The optional app lock (Settings > Privacy) covers every screen,
      // tabs and pushed screens alike, while someone is signed in.
      builder: (context, child) => Stack(
        children: [
          AppLockGate(
            active: signedIn,
            child: child ?? const SizedBox.shrink(),
          ),
          if (!restored) const SplashScreen(),
        ],
      ),
    );
  }
}
