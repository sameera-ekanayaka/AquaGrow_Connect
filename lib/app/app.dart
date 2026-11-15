import 'package:aquagrow_mobile/app/router/app_router.dart';
import 'package:aquagrow_mobile/core/theme/app_theme.dart';
import 'package:aquagrow_mobile/features/onboarding/presentation/splash_screen.dart';
import 'package:aquagrow_mobile/features/settings/application/theme_mode_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Root widget: theme and router. Shows the splash screen until the saved
/// sign-in session is restored, so the user never sees the wrong screen flash.
class AquaGrowApp extends ConsumerWidget {
  const AquaGrowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restored = ref.watch(authSessionProvider.select((s) => s.isRestored));
    return MaterialApp.router(
      title: 'AquaGrow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) =>
          restored ? child ?? const SizedBox.shrink() : const SplashScreen(),
    );
  }
}
