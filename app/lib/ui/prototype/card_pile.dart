// Copyright 2026 Christian Delicaat. All rights reserved.

// PROTOTYPE: the "pile of cards" background: the game's cards spread out (or your own photo),
// blurred and partly desaturated. CardsBackdrop in glass.dart puts the game's colors on top.

import 'dart:math';
import 'dart:ui';

import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/ui/prototype/glass.dart';
import 'package:flutter/material.dart';

// Your own background photo per game, e.g. a pile of real cards. Add the file to assets/ and
// pubspec.yaml, then map it here; games without one get a generated pile of cardbacks.
const customBackgrounds = <Tcg, String>{
  // Tcg.pokemon: 'assets/backgrounds/pokemon.jpg',
};

// The cards themselves (your own photo for the game, or the generated pile), blurred and partly
// desaturated. "All games" mixes the cards of every game.
class CardPileLayer extends StatelessWidget {
  final Tcg? game;
  final double blur;
  final double saturation; // 1 = original colors, 0 = grey

  const CardPileLayer({super.key, required this.game, required this.blur, required this.saturation});

  @override
  Widget build(BuildContext context) {
    final custom = customBackgrounds[game];

    return ImageFiltered(
      // Clamp: the screen edges stay filled instead of fading out
      imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur, tileMode: TileMode.clamp),
      child: ColorFiltered(
        colorFilter: ColorFilter.matrix(_saturation(saturation)),
        child: custom != null ? Image.asset(custom, fit: BoxFit.cover) : _CardPile(games: game == null ? Tcg.values : [game!]),
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

// Cards scattered over the whole area at random angles, overlapping like a pile on a table.
// Always the same layout for the same games (fixed random seed).
class _CardPile extends StatelessWidget {
  final List<Tcg> games;

  const _CardPile({required this.games});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final random = Random(games.first.index + games.length * 31);
        final cardWidth = size.width * 0.2; // About 5 cards across, like a real pile photographed from above
        final cardHeight = cardWidth / CardThumb.aspect;

        // Jittered grid with heavy overlap, a bit wider than the screen so no edge is left bare
        final cards = <Widget>[];
        final stepX = cardWidth * 0.68;
        final stepY = cardHeight * 0.52;
        for (var y = -cardHeight * 0.5; y < size.height + cardHeight * 0.2; y += stepY) {
          for (var x = -cardWidth * 0.5; x < size.width + cardWidth * 0.2; x += stepX) {
            final game = games[random.nextInt(games.length)];
            cards.add(Positioned(
              left: x + (random.nextDouble() - 0.5) * cardWidth * 0.6,
              top: y + (random.nextDouble() - 0.5) * cardHeight * 0.5,
              child: Transform.rotate(
                angle: (random.nextDouble() - 0.5) * 1.4, // Up to ±40°
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(1, 3))],
                  ),
                  child: CardThumb(game: game, width: cardWidth, radius: 5),
                ),
              ),
            ));
          }
        }
        cards.shuffle(random); // Random stacking order, so rows don't visibly overlap the same way

        return ClipRect(child: Stack(clipBehavior: Clip.none, children: cards));
      },
    );
  }
}
