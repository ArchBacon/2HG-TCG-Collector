// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/tmp/shared/models/tcg.dart';
import 'package:flutter/material.dart';

/// Colors per game: the page color under the background, the game's signature colors and an
/// accent for highlights (e.g. "new" counts). Follows the current theme.
class GamePalette {
  final Color base; // Page color under the card pile
  final List<Color> colors; // The game's signature colors; the first is used for tints and glows
  final Color accent; // Highlights

  const GamePalette({required this.base, required this.colors, required this.accent});

  /// The palette for [game] (null = all games) in the current theme. Light: a light page tinted
  /// with the game's color, and a deeper accent so it stays readable on light glass.
  static GamePalette of(BuildContext context, Tcg? game) {
    final palette = _dark(game);
    if (Theme.of(context).brightness == Brightness.dark) return palette;

    final hue = HSLColor.fromColor(palette.colors[1]).hue;
    final accent = HSLColor.fromColor(palette.accent);
    return GamePalette(
      base: HSLColor.fromAHSL(1, hue, 0.30, 0.86).toColor(), // Not too close to white, or white glass disappears on it
      colors: palette.colors,
      accent: accent.withLightness(0.38).withSaturation((accent.saturation * 1.1).clamp(0, 1)).toColor(),
    );
  }

  static GamePalette _dark(Tcg? game) => switch (game) {
    Tcg.pokemon => const GamePalette(
      base: Color(0xFF0B0D14),
      colors: [Color(0xFFE3350D), Color(0xFF3B4CCA), Color(0xFFFFCB05)],
      accent: Color(0xFFFFCB05),
    ),
    Tcg.mtg => const GamePalette(
      base: Color(0xFF0C0B10),
      colors: [Color(0xFFF26B21), Color(0xFF6B3FA0), Color(0xFF1E5F8C)],
      accent: Color(0xFFF5A35C),
    ),
    Tcg.onePiece => const GamePalette(
      base: Color(0xFF0A0D14),
      colors: [Color(0xFFD62828), Color(0xFF1D5FA8), Color(0xFFF4A261)],
      accent: Color(0xFFF4A261),
    ),
    Tcg.lorcana => const GamePalette(
      base: Color(0xFF0C0A14),
      colors: [Color(0xFF7B2CBF), Color(0xFF3A86FF), Color(0xFFC9A227)],
      accent: Color(0xFFE0C15A),
    ),
    Tcg.dragonBallFusion => const GamePalette(
      base: Color(0xFF0D0B0A),
      colors: [Color(0xFFFF8C00), Color(0xFF118AB2), Color(0xFFFFD166)],
      accent: Color(0xFFFFB347),
    ),
    null => const GamePalette( // All games: the brand green with neutral companions
      base: Color(0xFF0A0E12),
      colors: [Color(0xFF5CB85C), Color(0xFF3A6EA5), Color(0xFF7B5CB8)],
      accent: Color(0xFF7FD17F),
    ),
  };
}
