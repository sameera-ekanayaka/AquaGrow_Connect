import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_colors.dart';
import 'core/theme/biophilic_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: AquaGrowApp(),
    ),
  );
}

/// Root widget for the AquaGrow Connect mobile application.
class AquaGrowApp extends StatelessWidget {
  const AquaGrowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AquaGrow Connect',
      debugShowCheckedModeBanner: false,
      theme: BiophilicTheme.lightTheme,
      darkTheme: BiophilicTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.mintAccent),
          ),
        ),
      ),
    );
  }
}
