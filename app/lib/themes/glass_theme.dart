// Copyright 2026 Christian Delicaat. All rights reserved.

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Colors and settings for the "glass on a card pile" look, per theme.
///
/// Surfaces don't use a live blur: the background is already blurred, so a translucent fill (a
/// black wash on dark: smoked glass; a white wash on light: frosted glass) and a light edge make
/// them look like glass, without scrolling artifacts or performance cost. Real blur is only used
/// for the app bar, nav bar and sheets.
///
/// Registered on both [ThemeData]s in AppTheme; read it with `context.glass`. Because it's part of
/// the theme, switching between light and dark updates (and animates) everything that uses it.
@immutable
class GlassTheme extends ThemeExtension<GlassTheme> {
  // Glass surfaces
  final Color fill; // Chips, pills, fields, buttons
  final Color cardTop; // Glass cards: top...
  final Color cardBottom; // ...and bottom
  final Color edge; // Border around glass
  final Color divider; // Lines between rows in a glass card
  final Color track; // Empty part of progress bars and switches
  final Color bar; // App bar, nav bar and sheets (with a real blur behind them)
  final Color sheet; // Option sheets without a blur

  // Text and icons on glass and on the background
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color onAccent; // On a button filled with a game's accent color
  final Color positive; // Price up, "in store"
  final Color negative; // Price down

  // Cart badge
  final Color badge;
  final Color onBadge;

  // The card pile background: how much it's toned down so the glass and text stay readable
  final double backgroundBlur;
  final double backgroundSaturation; // 1 = the cards' own colors, 0 = grey
  final double backgroundCoverTop; // Opacity of the page color laid over the cards, at the top...
  final double backgroundCoverBottom; // ...and the bottom, where most content sits

  const GlassTheme({
    required this.fill,
    required this.cardTop,
    required this.cardBottom,
    required this.edge,
    required this.divider,
    required this.track,
    required this.bar,
    required this.sheet,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.onAccent,
    required this.positive,
    required this.negative,
    required this.badge,
    required this.onBadge,
    required this.backgroundBlur,
    required this.backgroundSaturation,
    required this.backgroundCoverTop,
    required this.backgroundCoverBottom,
  });

  /// Smoked glass: black wash, white text.
  static const dark = GlassTheme(
    fill: Color(0x7A000000), // Black 48%
    cardTop: Color(0x73000000), // Black 45%
    cardBottom: Color(0x94000000), // Black 58%
    edge: Color(0x24FFFFFF), // White 14%
    divider: Color(0x14FFFFFF), // White 8%
    track: Color(0x1AFFFFFF), // White 10%
    bar: Color(0xB310141A), // Page color at 70%
    sheet: Color(0xF010141A), // Page color at 94%
    textPrimary: Colors.white,
    textSecondary: Color(0xB3FFFFFF), // 70%
    textTertiary: Color(0x80FFFFFF), // 50%
    onAccent: Color(0xFF10141A), // Dark text on the bright dark-theme accents
    positive: Color(0xFF7FD17F),
    negative: Color(0xFFFF7A7A),
    badge: Color(0xFF5CB85C), // Brand green
    onBadge: Color(0xFF0A0E12),
    backgroundBlur: 6,
    backgroundSaturation: 0.6,
    backgroundCoverTop: 0.72,
    backgroundCoverBottom: 0.88,
  );

  /// Frosted glass: white wash, near-black ink. Same opacities as dark; the card gradient is
  /// mirrored (58% -> 45%) so the top is the lighter end on both themes.
  static const light = GlassTheme(
    fill: Color(0x7AFFFFFF), // White 48%
    cardTop: Color(0x94FFFFFF), // White 58%
    cardBottom: Color(0x73FFFFFF), // White 45%
    edge: Color(0x80FFFFFF), // White 50%
    divider: Color(0x1A12161D), // Ink 10%
    track: Color(0x1F12161D), // Ink 12%
    bar: Color(0xB3F4F6FA), // Light page color at 70%
    sheet: Color(0xF0F4F6FA), // Light page color at 94%
    textPrimary: Color(0xFF12161D),
    textSecondary: Color(0xB312161D), // 70%
    textTertiary: Color(0x8012161D), // 50%
    onAccent: Colors.white, // White text on the deeper light-theme accents
    positive: Color(0xFF2E8B3E),
    negative: Color(0xFFC6383F),
    badge: Color(0xFF2E8B3E), // Deeper green, for contrast on light
    onBadge: Colors.white,
    backgroundBlur: 6,
    backgroundSaturation: 0.6,
    backgroundCoverTop: 0.72,
    backgroundCoverBottom: 0.88,
  );

  /// For text on images and dark overlays (card thumbnails): white in both themes.
  static const onImage = Colors.white;
  static const onImageSecondary = Color(0xB3FFFFFF);

  @override
  GlassTheme copyWith({
    Color? fill,
    Color? cardTop,
    Color? cardBottom,
    Color? edge,
    Color? divider,
    Color? track,
    Color? bar,
    Color? sheet,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? onAccent,
    Color? positive,
    Color? negative,
    Color? badge,
    Color? onBadge,
    double? backgroundBlur,
    double? backgroundSaturation,
    double? backgroundCoverTop,
    double? backgroundCoverBottom,
  }) {
    return GlassTheme(
      fill: fill ?? this.fill,
      cardTop: cardTop ?? this.cardTop,
      cardBottom: cardBottom ?? this.cardBottom,
      edge: edge ?? this.edge,
      divider: divider ?? this.divider,
      track: track ?? this.track,
      bar: bar ?? this.bar,
      sheet: sheet ?? this.sheet,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      onAccent: onAccent ?? this.onAccent,
      positive: positive ?? this.positive,
      negative: negative ?? this.negative,
      badge: badge ?? this.badge,
      onBadge: onBadge ?? this.onBadge,
      backgroundBlur: backgroundBlur ?? this.backgroundBlur,
      backgroundSaturation: backgroundSaturation ?? this.backgroundSaturation,
      backgroundCoverTop: backgroundCoverTop ?? this.backgroundCoverTop,
      backgroundCoverBottom: backgroundCoverBottom ?? this.backgroundCoverBottom,
    );
  }

  // Blends between themes, so switching light/dark animates instead of jumping.
  @override
  GlassTheme lerp(GlassTheme? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    double d(double a, double b) => lerpDouble(a, b, t)!;
    return GlassTheme(
      fill: c(fill, other.fill),
      cardTop: c(cardTop, other.cardTop),
      cardBottom: c(cardBottom, other.cardBottom),
      edge: c(edge, other.edge),
      divider: c(divider, other.divider),
      track: c(track, other.track),
      bar: c(bar, other.bar),
      sheet: c(sheet, other.sheet),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      textTertiary: c(textTertiary, other.textTertiary),
      onAccent: c(onAccent, other.onAccent),
      positive: c(positive, other.positive),
      negative: c(negative, other.negative),
      badge: c(badge, other.badge),
      onBadge: c(onBadge, other.onBadge),
      backgroundBlur: d(backgroundBlur, other.backgroundBlur),
      backgroundSaturation: d(backgroundSaturation, other.backgroundSaturation),
      backgroundCoverTop: d(backgroundCoverTop, other.backgroundCoverTop),
      backgroundCoverBottom: d(backgroundCoverBottom, other.backgroundCoverBottom),
    );
  }
}

extension GlassThemeContext on BuildContext {
  /// The glass colors for the current theme.
  GlassTheme get glass => Theme.of(this).extension<GlassTheme>()!;

  bool get isDarkTheme => Theme.of(this).brightness == Brightness.dark;
}
