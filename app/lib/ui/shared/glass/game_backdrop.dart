// Copyright 2026 Christian Delicaat. All rights reserved.

import 'dart:ui';

import 'package:app/config/assets.dart';
import 'package:app/themes/game_palette.dart';
import 'package:app/themes/glass_theme.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:flutter/material.dart';

/// The background behind every screen: a pile of the game's cards (a pre-rendered image, see
/// tool/render_card_pile.py), blurred and partly desaturated, with the page color laid over it so
/// the glass and text on top stay readable. How strongly it's toned down comes from [GlassTheme].
///
/// Pre-rendered because building the pile live from ~150 card widgets cost ~17ms per frame while
/// scrolling (profile mode), against ~7ms for the image.
///
/// Cross-fades when the game changes.
class GameBackdrop extends StatelessWidget {
  final Tcg? game; // Null = all games mixed

  const GameBackdrop({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final base = GamePalette.of(context, game).base;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      child: RepaintBoundary(
        key: ValueKey(game),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: base),
            ImageFiltered(
              // Clamp: the screen edges stay filled instead of fading out
              imageFilter: ImageFilter.blur(
                sigmaX: glass.backgroundBlur,
                sigmaY: glass.backgroundBlur,
                tileMode: TileMode.clamp,
              ),
              child: ColorFiltered(
                colorFilter: ColorFilter.matrix(_saturation(glass.backgroundSaturation)),
                // gaplessPlayback: keeps the old image up while the new one loads, so switching
                // games doesn't flash the bare page color
                child: Image.asset(Assets.backgroundFor(game), fit: BoxFit.cover, gaplessPlayback: true),
              ),
            ),
            // Page color over the cards: lighter at the top, almost solid at the bottom
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    base.withValues(alpha: glass.backgroundCoverTop),
                    base.withValues(alpha: glass.backgroundCoverBottom),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Color matrix that scales saturation (1 = unchanged, 0 = grey).
  static List<double> _saturation(double s) {
    const r = 0.2126, g = 0.7152, b = 0.0722; // Luminance weights
    final i = 1 - s;
    return [
      r * i + s, g * i, b * i, 0, 0,
      r * i, g * i + s, b * i, 0, 0,
      r * i, g * i, b * i + s, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }
}
