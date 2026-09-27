// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:flutter/material.dart';

abstract final class AppColors {
  static const brandGreen = Color(0xFF5CB85C);

  static const darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: brandGreen,
    onPrimary: DarkColors.background, // Dark text on green reads better than white
    secondary: DarkColors.textMuted,
    onSecondary: DarkColors.background,
    error: DarkColors.error,
    onError: DarkColors.onError,
    surface: DarkColors.background,
    onSurface: DarkColors.textPrimary,
    onSurfaceVariant: DarkColors.textMuted,
    surfaceContainer: DarkColors.card,
    surfaceContainerLow: DarkColors.inset,
    outline: DarkColors.cardBorder,
    outlineVariant: DarkColors.insetBorder,
  );

  static const lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: brandGreen,
    onPrimary: LightColors.textPrimary, // Same dark-on-green as the dark theme
    secondary: LightColors.textMuted,
    onSecondary: LightColors.card,
    error: LightColors.error,
    onError: LightColors.onError,
    surface: LightColors.background,
    onSurface: LightColors.textPrimary,
    onSurfaceVariant: LightColors.textMuted,
    surfaceContainer: LightColors.card,
    surfaceContainerLow: LightColors.inset,
    outline: LightColors.cardBorder,
    outlineVariant: LightColors.insetBorder,
  );
}

/// Colors from the Google Stitch design.
abstract final class DarkColors {
  static const background = Color(0xFF10141A);
  static const card = Color(0xFF181C22);
  static const cardBorder = Color(0x0FFFFFFF); // white 6%

  /// Tiles and pills inside a card.
  static const inset = Color(0x08FFFFFF); // white 3%
  static const insetBorder = Color(0x0DFFFFFF); // white 5%

  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFF0F3FF);
  static const textMuted = Color(0xFF8B9BB4);

  // Not in the Stitch design; Material's default dark error colors.
  static const error = Color(0xFFFFB4AB);
  static const onError = Color(0xFF690005);
}

/// Not in the Stitch design; derived from the dark colors (same hues, inverted lightness).
abstract final class LightColors {
  static const background = Color(0xFFF4F6F9);
  static const card = Color(0xFFFFFFFF);
  static const cardBorder = Color(0x14000000); // black 8%

  /// Tiles and pills inside a card.
  static const inset = Color(0x08000000); // black 3%
  static const insetBorder = Color(0x0F000000); // black 6%

  static const textPrimary = Color(0xFF10141A); // The dark background
  static const textSecondary = Color(0xFF1F2530);
  static const textMuted = Color(0xFF5B6B84); // Darker than the dark theme's muted, to stay readable on white

  // Material's default light error colors.
  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
}
