// Copyright 2026 Christian Delicaat. All rights reserved.

// PROTOTYPE: the visual building blocks for the "glass on an ambient backdrop" direction.
//
// The idea: the backdrop is already soft and blurred, so cards don't need a live BackdropFilter to
// look frosted. A translucent fill (a black wash on dark: smoked glass; a white wash on light:
// frosted glass) and a light edge do the job, with no scrolling artifacts and no performance cost.
// Real blur is kept for the app bar and nav bar.
//
// Light and dark: the colors below follow ProtoTheme.brightness, which MainApp keeps in sync with
// the app's theme, and rebuilds the whole app when it changes. Not how a real theme should work
// (that would go through ThemeData), but it lets the prototype switch without rewriting every screen.

import 'dart:ui';

import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/ui/prototype/card_pile.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------------------------
// Light / dark
// ---------------------------------------------------------------------------------------------

// The theme picked in the prototype settings.
final protoThemeMode = ValueNotifier(ThemeMode.dark);

abstract final class ProtoTheme {
  // The brightness actually in use (system resolved); set by MainApp.
  static var brightness = Brightness.dark;

  static bool get isDark => brightness == Brightness.dark;
}

// Fills and edges for glass surfaces, per theme: a black wash on dark (smoked glass), a white wash
// on light (frosted glass).
class GlassColors {
  final Color fill; // Chips, pills, fields, buttons on the backdrop
  final Color cardTop; // Glass cards: top...
  final Color cardBottom; // ...and bottom
  final Color edge; // Border around glass
  final Color divider; // Lines between rows in a glass card
  final Color track; // Empty part of progress bars
  final Color bar; // App bar, nav bar and sheets (real blur behind it)

  const GlassColors._({
    required this.fill,
    required this.cardTop,
    required this.cardBottom,
    required this.edge,
    required this.divider,
    required this.track,
    required this.bar,
  });

  static const dark = GlassColors._(
    fill: Color(0x7A000000), // Black 48%
    cardTop: Color(0x73000000), // Black 45%
    cardBottom: Color(0x94000000), // Black 58%
    edge: Color(0x24FFFFFF), // White 14%
    divider: Color(0x14FFFFFF), // White 8%
    track: Color(0x1AFFFFFF), // White 10%
    bar: Color(0xB310141A), // Page color at 70%
  );

  static const light = GlassColors._(
    // Same opacities as dark. The card gradient is mirrored (58% -> 45% instead of 45% -> 58%) so
    // the top is the lighter end on both themes: less black on dark, more white on light.
    fill: Color(0x7AFFFFFF), // White 48%
    cardTop: Color(0x94FFFFFF), // White 58%
    cardBottom: Color(0x73FFFFFF), // White 45%
    edge: Color(0x80FFFFFF), // White 50%
    divider: Color(0x1A12161D), // Ink 10%
    track: Color(0x1F12161D), // Ink 12%
    bar: Color(0xB3F4F6FA), // Light page color at 70%
  );

  static GlassColors get current => ProtoTheme.isDark ? dark : light;

  static GlassColors of(BuildContext context) => current;
}

// Text and icon colors on the backdrop and on glass. On dark: white; on light: near-black ink.
abstract final class GlassText {
  static const _ink = Color(0xFF12161D);

  static Color get primary => ProtoTheme.isDark ? Colors.white : _ink;
  static Color get secondary => ProtoTheme.isDark ? const Color(0xB3FFFFFF) : const Color(0xB312161D); // 70%
  static Color get tertiary => ProtoTheme.isDark ? const Color(0x80FFFFFF) : const Color(0x8012161D); // 50%

  // For text on images and dark overlays (card thumbnails): always white, in both themes.
  static const onImage = Colors.white;
  static const onImageSecondary = Color(0xB3FFFFFF);

  // For text on a filled accent button: dark on dark theme's bright accents, white on light's
  // deeper ones.
  static Color get onAccent => ProtoTheme.isDark ? const Color(0xFF10141A) : Colors.white;

  // Positive / negative, e.g. price changes and "in store".
  static Color get positive => ProtoTheme.isDark ? const Color(0xFF7FD17F) : const Color(0xFF2E8B3E);
  static Color get negative => ProtoTheme.isDark ? const Color(0xFFFF7A7A) : const Color(0xFFC6383F);
}

// ---------------------------------------------------------------------------------------------
// Colors per game
// ---------------------------------------------------------------------------------------------

class GamePalette {
  final Color base; // Page color underneath everything
  final List<Color> glows; // Three soft color fields: top-left, right, bottom-left
  final Color accent; // Highlights, e.g. "new" counts

  const GamePalette({required this.base, required this.glows, required this.accent});

  // The palette for the current theme. Light: a very light page tinted with the game's color, and
  // a deeper accent so it stays readable on light glass.
  static GamePalette of(Tcg? game) {
    final palette = _dark(game);
    if (ProtoTheme.isDark) return palette;

    final hue = HSLColor.fromColor(palette.glows[1]).hue;
    final accent = HSLColor.fromColor(palette.accent);
    return GamePalette(
      base: HSLColor.fromAHSL(1, hue, 0.30, 0.86).toColor(), // Not too close to white, or white glass disappears on it
      glows: palette.glows,
      accent: accent.withLightness(0.38).withSaturation((accent.saturation * 1.1).clamp(0, 1)).toColor(),
    );
  }

  static GamePalette _dark(Tcg? game) => switch (game) {
    Tcg.pokemon => const GamePalette(
      base: Color(0xFF0B0D14),
      glows: [Color(0xFFE3350D), Color(0xFF3B4CCA), Color(0xFFFFCB05)],
      accent: Color(0xFFFFCB05),
    ),
    Tcg.mtg => const GamePalette(
      base: Color(0xFF0C0B10),
      glows: [Color(0xFFF26B21), Color(0xFF6B3FA0), Color(0xFF1E5F8C)],
      accent: Color(0xFFF5A35C),
    ),
    Tcg.onePiece => const GamePalette(
      base: Color(0xFF0A0D14),
      glows: [Color(0xFFD62828), Color(0xFF1D5FA8), Color(0xFFF4A261)],
      accent: Color(0xFFF4A261),
    ),
    Tcg.lorcana => const GamePalette(
      base: Color(0xFF0C0A14),
      glows: [Color(0xFF7B2CBF), Color(0xFF3A86FF), Color(0xFFC9A227)],
      accent: Color(0xFFE0C15A),
    ),
    Tcg.dragonBallFusion => const GamePalette(
      base: Color(0xFF0D0B0A),
      glows: [Color(0xFFFF8C00), Color(0xFF118AB2), Color(0xFFFFD166)],
      accent: Color(0xFFFFB347),
    ),
    null => const GamePalette( // All games: the brand green with neutral companions
      base: Color(0xFF0A0E12),
      glows: [Color(0xFF5CB85C), Color(0xFF3A6EA5), Color(0xFF7B5CB8)],
      accent: Color(0xFF7FD17F),
    ),
  };
}

// ---------------------------------------------------------------------------------------------
// Backdrops
// ---------------------------------------------------------------------------------------------

// Soft color fields in the game's palette. Cross-fades when the game changes.
class MeshBackdrop extends StatelessWidget {
  final Tcg? game;

  const MeshBackdrop({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      child: _Mesh(
        key: ValueKey(game),
        palette: GamePalette.of(game),
        glowStrength: ProtoTheme.isDark ? 1 : 0.5, // Strong colors on a light page get garish
      ),
    );
  }
}

// The game's card pile (card_pile.dart) under the same color fields, with the page color laid over it
// so the cards stay in the background.
class CardsBackdrop extends StatelessWidget {
  final Tcg? game;

  const CardsBackdrop({super.key, required this.game});

  // How the cards are toned down, per theme. The cover is the page color laid over the cards: dark
  // on dark, light on light, so the cards never fight the theme.
  static const _dark = (blur: 6.0, saturation: 0.6, cover: [0.72, 0.88], glow: 0.0); // glow: the 3 color fields, off
  static const _light = (blur: 6.0, saturation: 0.6, cover: [0.72, 0.88], glow: 0.0);

  @override
  Widget build(BuildContext context) {
    final palette = GamePalette.of(game);
    final look = ProtoTheme.isDark ? _dark : _light;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      child: RepaintBoundary(
        key: ValueKey(game),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: palette.base),
            CardPileLayer(game: game, blur: look.blur, saturation: look.saturation),
            // Page color over the cards: lighter at the top, almost solid at the bottom
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [palette.base.withValues(alpha: look.cover[0]), palette.base.withValues(alpha: look.cover[1])],
                ),
              ),
            ),
            _Mesh(palette: palette, baseOpacity: 0, glowStrength: look.glow),
          ],
        ),
      ),
    );
  }
}

class _Mesh extends StatelessWidget {
  final GamePalette palette;
  final double baseOpacity; // 0 = only the color fields, for laying over something else
  final double glowStrength; // Multiplies the color fields' opacity

  const _Mesh({super.key, required this.palette, this.baseOpacity = 1, this.glowStrength = 1});

  @override
  Widget build(BuildContext context) {
    // (center, radius, opacity) per glow
    const spots = [
      (Alignment(-1.1, -0.9), 1.1, 0.55),
      (Alignment(1.2, 0.05), 1.0, 0.45),
      (Alignment(-0.8, 1.1), 1.1, 0.35),
    ];

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(color: palette.base.withValues(alpha: baseOpacity)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            for (final (i, (center, radius, opacity)) in spots.indexed)
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: center,
                    radius: radius,
                    colors: [
                      palette.glows[i].withValues(alpha: opacity * glowStrength),
                      palette.glows[i].withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// The game's own artwork, blown up and heavily blurred, under the page color. Like Apple Music does
// with album art. Cross-fades when the game changes.
class ArtworkBackdrop extends StatelessWidget {
  final Tcg? game;

  const ArtworkBackdrop({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final base = GamePalette.of(game).base;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      child: RepaintBoundary(
        key: ValueKey(game),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: base),
            if (game != null)
              // Scaled up so the blurred edges fall outside the screen
              Transform.scale(
                scale: 1.4,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                  child: Image.asset(game!.imageAsset, fit: BoxFit.cover),
                ),
              )
            else
              const MeshBackdrop(game: null),
            // Page color over the art so text and glass stay readable; heavier at the bottom
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [base.withValues(alpha: 0.5), base.withValues(alpha: 0.9)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------------
// Glass surfaces
// ---------------------------------------------------------------------------------------------

// Glass card without a live blur. No drop shadow: through a translucent fill it shows as a smudge
// (the "inset shadow" look from before).
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final glass = GlassColors.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: glass.edge), // The glass edge
    );

    return Material(
      type: MaterialType.transparency,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: ShapeDecoration(
          shape: shape,
          // Lighter at the top, like light catching the glass
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [glass.cardTop, glass.cardBottom],
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

// Small rounded label on glass, e.g. "3 new".
class GlassChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color; // Null = the regular text color
  final bool filled; // Filled with the color, for emphasis

  const GlassChip({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? GlassText.primary;
    final glass = GlassColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? color.withValues(alpha: 0.2) : glass.fill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: filled ? color.withValues(alpha: 0.45) : glass.edge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
          ],
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// Card-shaped thumbnail: the game's cardback as a stand-in for the card image.
class CardThumb extends StatelessWidget {
  final Tcg game;
  final double width;
  final double radius;

  const CardThumb({super.key, required this.game, required this.width, this.radius = 8});

  static const aspect = 146 / 204; // Width / height of the cardback images

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(game.imageAsset, width: width, height: width / aspect, fit: BoxFit.cover),
    );
  }
}
