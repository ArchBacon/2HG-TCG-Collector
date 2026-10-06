// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/themes/colors.dart';
import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData lightTheme = _theme(AppColors.lightColorScheme, secondaryText: LightColors.textSecondary);

  static ThemeData darkTheme = _theme(AppColors.darkColorScheme, secondaryText: DarkColors.textSecondary);

  // Both themes share the same layout; only the colors differ.
  static ThemeData _theme(ColorScheme colors, {required Color secondaryText}) {
    return ThemeData(
      brightness: colors.brightness,
      fontFamily: 'Inter',
      colorScheme: colors,
      scaffoldBackgroundColor: colors.surface,
      textTheme: TextTheme(
        headlineLarge: const TextStyle(fontSize: 32, fontWeight: FontWeight.w500),
        headlineSmall: const TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
        titleMedium: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        bodyLarge: const TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
        bodyMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
        bodySmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: colors.onSurfaceVariant,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: colors.onSurfaceVariant,
        ),
        labelLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: secondaryText,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          color: Colors.deepOrange,
          fontSize: 18.0,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
