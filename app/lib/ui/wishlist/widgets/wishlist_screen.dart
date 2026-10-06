// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/routing/routes.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/ui/shared/glass_app_bar.dart';
import 'package:app/ui/shared/glass_nav_bar.dart';
import 'package:app/ui/wishlist/view_models/wishlist_viewmodel.dart';
import 'package:app/ui/wishlist/widgets/new_in_store_carousel.dart';
import 'package:app/ui/wishlist/widgets/wishlist_game_list.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({
    super.key,
    required this.viewModel,
  });

  final WishlistViewModel viewModel;

  @override
  State<StatefulWidget> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant WishlistScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(title: Text('Wishlist')),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, child) {
          final summary = widget.viewModel.summary;

          final games = (summary?.tcgs.entries.map((entry) {
            final game = Tcg.values.firstWhere((t) => t.slug == entry.key);
            final (availableShare, newCount) = _mockStore[game] ?? (0.0, 0);
            return WishlistGameSummary(
              game: game,
              cardCount: entry.value.collected,
              availableCount: (entry.value.collected * availableShare).round(),
              newCount: newCount,
            );
          }).toList() ?? [])
          // sort tcgs by high to low collected cards
          ..sort((a, b) => b.cardCount.compareTo(a.cardCount));

          return ListView(
            padding: EdgeInsets.fromLTRB(12, GlassAppBar.contentTopPadding(context) + 12, 12, GlassNavBar.contentBottomPadding(context) + 12),
            children: [
              NewInStoreCarousel(
                cards: _mockNewInStore,
                onSelected: (card) {}, // TODO: open the card in the store
              ),
              const SizedBox(height: 12), // Gap between carousel and game list, same as between game cards
              WishlistGameList(
                games: games,
                onSelected: (tcg) => context.push(Routes.overviewFor(tcg)),
              ),
            ],
          );
        }
      ),
    );
  }
}

// TODO: replace with store data once the API provides it.
// Per game: share of the wishlisted cards that's in the store, and how many of those are new.
// Lorcana has nothing in store and MTG nothing new, to show those states.
const _mockStore = <Tcg, (double, int)>{
  Tcg.pokemon: (0.32, 3),
  Tcg.mtg: (0.18, 0),
  Tcg.onePiece: (0.45, 5),
  Tcg.lorcana: (0.0, 0),
  Tcg.dragonBallFusion: (0.6, 1),
};

// TODO: replace with store data once the API provides it.
// Wishlisted cards recently added to the store; counts per game match the "new" badges in _mockStore.
const _mockNewInStore = [
  NewInStoreCard(game: Tcg.onePiece, name: 'Portgas.D.Ace', number: 'OP13-119'),
  NewInStoreCard(game: Tcg.pokemon, name: 'Umbreon ex', number: '161/131'),
  NewInStoreCard(game: Tcg.onePiece, name: 'Shanks', number: 'OP17-120'),
  NewInStoreCard(game: Tcg.dragonBallFusion, name: 'Son Goku', number: 'FB06-138'),
  NewInStoreCard(game: Tcg.pokemon, name: 'Sylveon ex', number: '156/131'),
  NewInStoreCard(game: Tcg.onePiece, name: 'Monkey.D.Luffy', number: 'OP17-001'),
  NewInStoreCard(game: Tcg.onePiece, name: 'Roronoa Zoro', number: 'OP13-118'),
  NewInStoreCard(game: Tcg.pokemon, name: 'Mega Gardevoir ex', number: '178/132'),
  NewInStoreCard(game: Tcg.onePiece, name: 'Nami', number: 'OP17-081'),
];
