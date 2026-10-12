// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/services/mock/mock_data.dart';
import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/ui/shared/app_state.dart';
import 'package:app/ui/wishlist/widgets/wishlist_game_view.dart';
import 'package:flutter/material.dart';

/// Wishlist tab: the wishlist of the selected game.
class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: MockData.wishlist(),
      builder: (context, snapshot) {
        final cards = snapshot.data ?? const <TcgCard>[];
        return ValueListenableBuilder(
          valueListenable: selectedGame,
          builder: (context, game, _) => WishlistGameView(game: game, cards: cards.where((c) => c.game == game).toList()),
        );
      },
    );
  }
}
