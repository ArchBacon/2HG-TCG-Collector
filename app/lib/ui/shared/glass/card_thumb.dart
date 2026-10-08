// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/routing/navigation.dart';
import 'package:app/themes/glass_theme.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:flutter/material.dart';

/// Card-shaped thumbnail: the game's cardback as a stand-in for the card image.
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

/// Card thumbnail with its name and number over a dark fade at the bottom. Opens the card.
class CardOverlayThumb extends StatelessWidget {
  final TcgCard card;
  final double width;

  const CardOverlayThumb({super.key, required this.card, required this.width});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.openCard(card),
      child: SizedBox(
        width: width,
        height: width / CardThumb.aspect,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(card.game.imageAsset, fit: BoxFit.cover),
              // Dark fade at the bottom, so the text stays readable on any card
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xE6000000), Color(0xB3000000), Color(0x00000000)],
                    stops: [0, 0.3, 0.75],
                  ),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: GlassTheme.onImage, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      card.number,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: GlassTheme.onImageSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              // Thin glass edge, so the card reads as an object on the background
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0x24FFFFFF)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
