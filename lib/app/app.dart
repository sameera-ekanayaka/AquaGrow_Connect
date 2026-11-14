import 'package:aquagrow_mobile/app/router/app_router.dart';
import 'package:aquagrow_mobile/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Light, dark or follow the phone. Changed from the settings screen.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

/// Root widget: theme and router. No screens are built here.
class AquaGrowApp extends ConsumerWidget {
  const AquaGrowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'AquaGrow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
