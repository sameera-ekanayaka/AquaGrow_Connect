import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// The single Material 3 theme for the app, built from the Figma tokens.
///
/// Text styles follow the Figma text styles (line height 1.4). Figma uses Inter;
/// the app uses the Android system font (Roboto) until Inter is bundled under
/// `assets/fonts/` (runtime font downloads would fail offline and in tests):
///
/// | Figma style | Flutter style      | Size / weight |
/// |-------------|--------------------|---------------|
/// | Title       | headlineMedium     | 28 / 700      |
/// | Section     | titleLarge         | 20 / 700      |
/// | Strong      | titleMedium        | 16 / 600      |
/// | Body        | bodyLarge          | 16 / 400      |
/// | Label       | labelLarge         | 14 / 600      |
/// | Meta        | bodySmall          | 12 / 500      |
/// | Sensor value| displaySmall       | 28 / 700      |
///
/// Use `Theme.of(context).textTheme.titleLarge` and so on. Never build a
/// `TextStyle` with a raw font size inside a feature.
abstract final class AppTheme {
  /// Inter, bundled in `assets/fonts/` and declared in pubspec.yaml.
  static const fontFamily = 'Inter';

  static ThemeData get light => _build(AgColors.light, Brightness.light);
  static ThemeData get dark => _build(AgColors.dark, Brightness.dark);

  static ThemeData _build(AgColors c, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.text,
      onPrimary: c.onDark,
      secondary: c.brand,
      onSecondary: AgColors.light.text,
      tertiary: c.warning,
      onTertiary: c.onDark,
      error: c.critical,
      onError: c.onDark,
      surface: c.surface,
      onSurface: c.text,
      onSurfaceVariant: c.textSecondary,
      outline: c.border,
      outlineVariant: c.border,
      surfaceContainerHighest: c.subtle,
    );

    final textTheme = _textTheme(c, brightness);
    // Minimal UI: cards are filled with the surface colour, no border.
    final cardShape = RoundedRectangleBorder(
      borderRadius: AgRadius.all(AgRadius.r20),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      fontFamily: fontFamily,
      textTheme: textTheme,
      extensions: [c],
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: cardShape,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.text,
          foregroundColor: c.onDark,
          minimumSize: const Size.fromHeight(kMinTouchTarget),
          shape: RoundedRectangleBorder(borderRadius: AgRadius.all(AgRadius.r16)),
          textStyle: textTheme.titleMedium,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.text,
          minimumSize: const Size.fromHeight(kMinTouchTarget),
          side: BorderSide(color: c.border),
          shape: RoundedRectangleBorder(borderRadius: AgRadius.all(AgRadius.r16)),
          textStyle: textTheme.titleMedium,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.text,
          minimumSize: const Size(kMinTouchTarget, kMinTouchTarget),
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AgSpace.s16,
          vertical: AgSpace.s16,
        ),
        border: OutlineInputBorder(
          borderRadius: AgRadius.all(AgRadius.r16),
          borderSide: BorderSide(color: c.border),
        ),
        // Minimal UI: filled fields, no outline until focused.
        enabledBorder: OutlineInputBorder(
          borderRadius: AgRadius.all(AgRadius.r16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AgRadius.all(AgRadius.r16),
          borderSide: BorderSide(color: c.text, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AgRadius.all(AgRadius.r16),
          borderSide: BorderSide(color: c.critical),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        indicatorColor: c.brandSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.bodySmall?.copyWith(
            color: states.contains(WidgetState.selected) ? c.text : c.textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? c.text : c.textSecondary,
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? c.brand : c.subtle,
        ),
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? c.text : c.textSecondary,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: AgRadius.all(AgRadius.r24)),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyLarge,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.text,
        contentTextStyle: textTheme.bodyLarge?.copyWith(color: c.onDark),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
    );
  }

  static TextTheme _textTheme(AgColors c, Brightness brightness) {
    final base = brightness == Brightness.dark
        ? ThemeData(brightness: Brightness.dark).textTheme
        : ThemeData(brightness: Brightness.light).textTheme;

    TextStyle style(double size, FontWeight weight, Color color) => TextStyle(
          fontSize: size,
          fontWeight: weight,
          height: 1.4,
          color: color,
        );

    return base.copyWith(
      displaySmall: style(28, FontWeight.w700, c.text),
      headlineMedium: style(28, FontWeight.w700, c.text),
      titleLarge: style(20, FontWeight.w700, c.text),
      titleMedium: style(16, FontWeight.w600, c.text),
      bodyLarge: style(16, FontWeight.w400, c.text),
      bodyMedium: style(14, FontWeight.w400, c.text),
      labelLarge: style(14, FontWeight.w600, c.text),
      bodySmall: style(12, FontWeight.w500, c.textSecondary),
      labelSmall: style(12, FontWeight.w500, c.textSecondary),
    );
  }
}
