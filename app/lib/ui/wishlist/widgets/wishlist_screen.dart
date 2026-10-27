// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/themes/game_palette.dart';
import 'package:app/themes/glass_theme.dart';
import 'package:app/ui/shared/glass/glass_scaffold.dart';
import 'package:app/ui/shared/glass/loading_indicator.dart';
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
      listenable: Listenable.merge([viewModel, viewModel.load]),
      builder: (context, _) {
        final newInStore = viewModel.newInStore;
        final bySet = viewModel.bySet;

        return GlassScaffold(
          title: 'Wishlist',
          game: viewModel.tcg,
          search: viewModel.search,
          searchHint: 'Search wishlist',
          children: [
            if (viewModel.load.running)
              LoadingSection(color: accent)
            else ...[
              WishlistSummary(cards: viewModel.cards, accent: accent),
              const SizedBox(height: 14),
              if (newInStore.isNotEmpty) ...[
                NewInStoreCard(cards: newInStore, accent: accent),
                const SizedBox(height: 14),
              ],
              for (final MapEntry(key: setName, value: setCards) in bySet.entries) ...[
                WishlistSetCard(setName: setName, cards: setCards, accent: accent),
                const SizedBox(height: 14),
              ],
              if (bySet.isEmpty && viewModel.search.value.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No wishlisted cards match this search',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.glass.textSecondary),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}
