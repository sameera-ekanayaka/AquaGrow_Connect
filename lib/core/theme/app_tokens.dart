import 'package:flutter/material.dart';

/// Design tokens copied from the Figma file "AquaGrow", page
/// "01 — Refined Direction" (variables prefixed `--ag-`).
///
/// RULE: feature code never writes a hex colour, a raw padding number or a
/// raw radius. Use these tokens, or `context.ag` for colours. See DESIGN.md.

/// Spacing scale in logical pixels (`--ag-space-*`).
abstract final class AgSpace {
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;

  /// Side padding of every screen.
  static const double screen = s20;
}

/// Corner radii (`--ag-radius-*`).
abstract final class AgRadius {
  static const double r16 = 16; // buttons, small cards, nav item
  static const double r20 = 20; // sensor cards, crop tiles, task card
  static const double r24 = 24; // hero card, bottom navigation
  static const double r32 = 32;
  static const double pill = 999; // badges

  static BorderRadius all(double r) => BorderRadius.circular(r);
}

/// Minimum touch target from the Material and lecture 5 guidelines.
const double kMinTouchTarget = 48;

/// Colour roles from Figma, as a [ThemeExtension] so light and dark themes
/// swap automatically. Read them with `context.ag.brand`, `context.ag.text`, etc.
@immutable
class AgColors extends ThemeExtension<AgColors> {
  const AgColors({
    required this.background,
    required this.surface,
    required this.subtle,
    required this.border,
    required this.text,
    required this.textSecondary,
    required this.onDark,
    required this.brand,
    required this.brandSurface,
    required this.warning,
    required this.warningSurface,
    required this.critical,
    required this.criticalSurface,
  });

  /// Screen background (`--ag-color-background`).
  final Color background;

  /// Cards and sheets (`--ag-color-surface`).
  final Color surface;

  /// Quiet panels and icon buttons (`--ag-color-subtle`).
  final Color subtle;

  /// 1 px card borders (`--ag-color-border`).
  final Color border;

  /// Primary text, and the dark button fill (`--ag-color-text`).
  final Color text;

  /// Labels, captions, inactive nav (`--ag-color-secondary`).
  final Color textSecondary;

  /// Text on dark fills, such as the primary button (`--ag-color-on-dark`).
  final Color onDark;

  /// AquaGrow lime: live badges, selected states (`--ag-color-brand`).
  final Color brand;

  /// Lime tint behind the selected nav item (`--ag-color-lime-surface`).
  final Color brandSurface;

  /// Sensor value out of range (`--ag-color-warning`).
  final Color warning;

  /// Background of attention cards (`--ag-color-warning-surface`).
  final Color warningSurface;

  /// Dangerous values and destructive actions. Not in Figma; added for alerts.
  final Color critical;

  /// Background of critical alert cards.
  final Color criticalSurface;

  static const light = AgColors(
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFF5F6F3),
    subtle: Color(0xFFECEDE9),
    border: Color(0xFFE6E7E3),
    text: Color(0xFF111311),
    textSecondary: Color(0xFF676A65),
    onDark: Color(0xFFFFFFFF),
    brand: Color(0xFFA8E63D),
    brandSurface: Color(0xFFF1F9DC),
    warning: Color(0xFF8A5300),
    warningSurface: Color(0xFFFFF3E0),
    critical: Color(0xFFB3261E),
    criticalSurface: Color(0xFFFDECEA),
  );

  static const dark = AgColors(
    background: Color(0xFF0A0A0A),
    surface: Color(0xFF161616),
    subtle: Color(0xFF1F1F1F),
    border: Color(0xFF2A2A2A),
    text: Color(0xFFFAFAFA),
    textSecondary: Color(0xFFA3A3A3),
    onDark: Color(0xFF0A0A0A),
    brand: Color(0xFFA8E63D),
    brandSurface: Color(0xFF26330F),
    warning: Color(0xFFF5B04C),
    warningSurface: Color(0xFF2E2110),
    critical: Color(0xFFF2B8B5),
    criticalSurface: Color(0xFF3A1A18),
  );

  @override
  AgColors copyWith({
    Color? background,
    Color? surface,
    Color? subtle,
    Color? border,
    Color? text,
    Color? textSecondary,
    Color? onDark,
    Color? brand,
    Color? brandSurface,
    Color? warning,
    Color? warningSurface,
    Color? critical,
    Color? criticalSurface,
  }) {
    return AgColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      subtle: subtle ?? this.subtle,
      border: border ?? this.border,
      text: text ?? this.text,
      textSecondary: textSecondary ?? this.textSecondary,
      onDark: onDark ?? this.onDark,
      brand: brand ?? this.brand,
      brandSurface: brandSurface ?? this.brandSurface,
      warning: warning ?? this.warning,
      warningSurface: warningSurface ?? this.warningSurface,
      critical: critical ?? this.critical,
      criticalSurface: criticalSurface ?? this.criticalSurface,
    );
  }

  @override
  AgColors lerp(ThemeExtension<AgColors>? other, double t) {
    if (other is! AgColors) return this;
    return AgColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      subtle: Color.lerp(subtle, other.subtle, t)!,
      border: Color.lerp(border, other.border, t)!,
      text: Color.lerp(text, other.text, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      onDark: Color.lerp(onDark, other.onDark, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      brandSurface: Color.lerp(brandSurface, other.brandSurface, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSurface: Color.lerp(warningSurface, other.warningSurface, t)!,
      critical: Color.lerp(critical, other.critical, t)!,
      criticalSurface: Color.lerp(criticalSurface, other.criticalSurface, t)!,
    );
  }
}

/// Shortcut: `context.ag.brand` instead of
/// `Theme.of(context).extension<AgColors>()!.brand`.
extension AgColorsContext on BuildContext {
  AgColors get ag => Theme.of(this).extension<AgColors>() ?? AgColors.light;
}
