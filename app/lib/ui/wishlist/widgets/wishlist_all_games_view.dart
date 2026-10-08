// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/themes/game_palette.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/ui/shared/glass/game_tile.dart';
import 'package:app/ui/shared/glass/glass_scaffold.dart';
import 'package:app/ui/wishlist/widgets/new_in_store_card.dart';
import 'package:app/ui/wishlist/widgets/wishlist_summary.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The wishlist with "All games" picked: totals and new-in-store across all games, and a tile per
/// game (tapping one picks that game).
class WishlistAllGamesView extends StatelessWidget {
  final List<TcgCard> cards;

  const WishlistAllGamesView({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    final accent = GamePalette.of(context, null).accent;
    final newCards = cards.where((c) => c.isNew).toList();
    final games = [for (final game in Tcg.values) (game, cards.where((c) => c.game == game).toList())]
      ..sort((a, b) => b.$2.length.compareTo(a.$2.length)); // Most wishlisted first

    return GlassScaffold(
      title: 'Wishlist',
      game: null,
      showGameSwitcher: false, // The game tiles below are the game picker on this page
      children: [
        WishlistSummary(cards: cards, accent: accent, caption: 'Wishlist across all games'),
        const SizedBox(height: 14),
        if (newCards.isNotEmpty) ...[
          NewInStoreCard(cards: newCards, accent: accent),
          const SizedBox(height: 14),
        ],
        GameTileGrid(
          tiles: [
            for (final (game, gameCards) in games)
              GameTile(
                game: game,
                stats: [
                  (LucideIcons.heart, '${gameCards.length}'),
                  (LucideIcons.shoppingCart, '${gameCards.where((c) => c.inStore).length}'),
                ],
                newCount: gameCards.where((c) => c.isNew).length,
              ),
          ],
        ),
      ],
    );
  }
}
