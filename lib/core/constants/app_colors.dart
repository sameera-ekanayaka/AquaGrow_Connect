import 'package:flutter/material.dart';

/// Centralized color palette based on biophilic design principles.
/// Uses soothing botanical greens, earthy tones, and high-contrast accents
/// to evoke an indoor living decor aesthetic.
class AppColors {
  AppColors._();

  // Primary Brand Colors
  static const Color primarySage = Color(0xFF2D6A4F);
  static const Color mintAccent = Color(0xFF52B788);
  static const Color forestDepth = Color(0xFF1B4332);
  static const Color softMint = Color(0xFFB7E4C7);
  static const Color lightMintBackground = Color(0xFFD8F3DC);

  // Dark Theme Surfaces
  static const Color darkBackground = Color(0xFF121816);
  static const Color darkSurface = Color(0xFF1E2623);
  static const Color darkSurfaceElevated = Color(0xFF25312C);
  static const Color darkBorder = Color(0xFF2D3C35);

  // Light Theme Surfaces
  static const Color lightBackground = Color(0xFFF7FAF8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF0F5F2);
  static const Color lightBorder = Color(0xFFE0EBE4);

  // Typography Colors
  static const Color textDarkPrimary = Color(0xFFE8F5E9);
  static const Color textDarkSecondary = Color(0xFF9EABA2);
  static const Color textLightPrimary = Color(0xFF1B4332);
  static const Color textLightSecondary = Color(0xFF5C6F64);

  // Status and Threshold Indicators
  static const Color statusOptimal = Color(0xFF2A9D8F);
  static const Color statusWarning = Color(0xFFF4A261);
  static const Color statusCritical = Color(0xFFE76F51);
  static const Color statusInfo = Color(0xFF457B9D);

  // Glassmorphic Overlay Tints
  static const Color glassDarkTint = Color(0x331E2623);
  static const Color glassLightTint = Color(0x40FFFFFF);
  static const Color glassBorder = Color(0x22FFFFFF);
}
