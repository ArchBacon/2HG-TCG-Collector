// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/domain/models/collection/card_collection.dart';
import 'package:app/themes/glass_theme.dart';
import 'package:app/tmp/core/utils/format.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/ui/shared/glass/card_thumb.dart';
import 'package:app/ui/shared/glass/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A collection on the Collection tab: the cards added to it last as a small fan, its name, and its
/// counts and value for the game.
class CollectionCard extends StatelessWidget {
  final CardCollection collection;
  final Tcg game; // For the cardback when it has no cards of this game yet
  final VoidCallback onTap;

  const CollectionCard({super.key, required this.collection, required this.game, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final empty = collection.cards == 0;

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      child: Row(
        children: [
          _Fan(game: game, collection: collection),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  collection.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: glass.textPrimary, fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  empty
                      ? 'No ${game.displayName} cards yet'
                      : '${collection.cards} ${collection.cards == 1 ? 'card' : 'cards'} · ${collection.copies} ${collection.copies == 1 ? 'copy' : 'copies'}',
                  style: TextStyle(color: glass.textSecondary, fontSize: 13),
                ),
                if (collection.value > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    formatEuro(collection.value),
                    style: TextStyle(color: glass.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ],
            ),
          ),
          Icon(LucideIcons.chevronRight, size: 20, color: glass.textTertiary),
        ],
      ),
    );
  }
}

/// Up to three cards, fanned out from the bottom; the game's cardback when there are none.
class _Fan extends StatelessWidget {
  final Tcg game;
  final CardCollection collection;

  const _Fan({required this.game, required this.collection});

  static const _cardWidth = 52.0;
  static const _angle = 0.12; // Radians between two cards

  @override
  Widget build(BuildContext context) {
    final previews = collection.previews.reversed.toList(); // The newest on top
    final count = previews.isEmpty ? 1 : previews.length;

    return SizedBox(
      width: _cardWidth + 26,
      height: _cardWidth * 1.4 + 8,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          for (var i = 0; i < count; i++)
            Transform.rotate(
              angle: (i - (count - 1) / 2) * _angle,
              alignment: Alignment.bottomCenter,
              child: CardThumb(
                game: game,
                imageUrl: previews.isEmpty ? null : previews[i].imageUrl,
                width: _cardWidth,
                radius: 5,
                store: true, // The collection's own cards
              ),
            ),
        ],
      ),
    );
  }
}
