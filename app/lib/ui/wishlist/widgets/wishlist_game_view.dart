// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/themes/game_palette.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/ui/shared/glass/glass_scaffold.dart';
import 'package:app/ui/wishlist/widgets/new_in_store_card.dart';
import 'package:app/ui/wishlist/widgets/wishlist_set_card.dart';
import 'package:app/ui/wishlist/widgets/wishlist_summary.dart';
import 'package:flutter/material.dart';

/// The wishlist of one game: totals, the cards that just came into the store, and every wishlisted
/// card in a grid per set.
class WishlistGameView extends StatelessWidget {
  final Tcg game;
  final List<TcgCard> cards;

  const WishlistGameView({super.key, required this.game, required this.cards});

  @override
  Widget build(BuildContext context) {
    final accent = GamePalette.of(context, game).accent;
    final newCards = cards.where((c) => c.isNew).toList();

    return GlassScaffold(
      title: 'Wishlist',
      game: game,
      children: [
        WishlistSummary(cards: cards, accent: accent),
        const SizedBox(height: 14),
        if (newCards.isNotEmpty) ...[
          NewInStoreCard(cards: newCards, accent: accent),
          const SizedBox(height: 14),
        ],
        for (final MapEntry(key: setName, value: setCards) in _groupBySet(cards).entries) ...[
          WishlistSetCard(setName: setName, cards: setCards, accent: accent),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  // Groups cards by set, keeping the order they first appear in.
  static Map<String, List<TcgCard>> _groupBySet(List<TcgCard> cards) {
    final groups = <String, List<TcgCard>>{};
    for (final card in cards) {
      groups.putIfAbsent(card.setName, () => []).add(card);
    }
    return groups;
  }
}
