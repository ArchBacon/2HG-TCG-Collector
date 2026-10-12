// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/themes/game_palette.dart';
import 'package:app/ui/shared/glass/glass_scaffold.dart';
import 'package:app/ui/wishlist/view_models/wishlist_viewmodel.dart';
import 'package:app/ui/wishlist/widgets/new_in_store_card.dart';
import 'package:app/ui/wishlist/widgets/wishlist_set_card.dart';
import 'package:app/ui/wishlist/widgets/wishlist_summary.dart';
import 'package:flutter/material.dart';

/// Wishlist tab: one game's wishlist. Totals, the cards that just came into the store, and every
/// wishlisted card in a grid per set.
class WishlistScreen extends StatelessWidget {
  final WishlistViewModel viewModel;

  const WishlistScreen({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final accent = GamePalette.of(context, viewModel.tcg).accent;

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final newInStore = viewModel.newInStore;

        return GlassScaffold(
          title: 'Wishlist',
          game: viewModel.tcg,
          children: [
            WishlistSummary(cards: viewModel.cards, accent: accent),
            const SizedBox(height: 14),
            if (newInStore.isNotEmpty) ...[
              NewInStoreCard(cards: newInStore, accent: accent),
              const SizedBox(height: 14),
            ],
            for (final MapEntry(key: setName, value: setCards) in viewModel.bySet.entries) ...[
              WishlistSetCard(setName: setName, cards: setCards, accent: accent),
              const SizedBox(height: 14),
            ],
          ],
        );
      },
    );
  }
}
