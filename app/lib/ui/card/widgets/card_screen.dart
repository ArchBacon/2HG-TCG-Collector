// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/domain/models/card/market_info.dart';
import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/themes/game_palette.dart';
import 'package:app/themes/glass_theme.dart';
import 'package:app/ui/card/view_models/card_viewmodel.dart';
import 'package:app/ui/card/widgets/buy_bar.dart';
import 'package:app/ui/card/widgets/card_details_list.dart';
import 'package:app/ui/card/widgets/card_hero.dart';
import 'package:app/ui/card/widgets/finish_selector.dart';
import 'package:app/ui/card/widgets/listings_section.dart';
import 'package:app/ui/card/widgets/ownership_card.dart';
import 'package:app/ui/card/widgets/price_card.dart';
import 'package:app/ui/shared/glass/game_backdrop.dart';
import 'package:app/ui/shared/glass/header_controls.dart';
import 'package:app/ui/shared/glass_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Card details, full screen over the nav bar. Collection and shop in one place: the card, its
/// price, your copies and wishlist status, and the store listings to buy it from, with an "Add to
/// cart" bar at the bottom. Borrows from Discogs: community have/want counts, and the marketplace
/// listings right on the item page.
class CardScreen extends StatelessWidget {
  final CardViewModel viewModel;

  const CardScreen({super.key, required this.viewModel});

  Future<void> _addToCart(BuildContext context, TcgCard card, StoreListing listing) async {
    await viewModel.addToCart.execute(listing);
    if (!context.mounted || !viewModel.addToCart.completed) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 96), // Above the buy bar
        content: Text('${card.name} added to cart'),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final card = viewModel.card;
        final market = viewModel.market;
        if (card == null || market == null) {
          return _NoCard(loading: viewModel.load.running || viewModel.load.result == null);
        }

        final glass = context.glass;
        final accent = GamePalette.of(context, card.game).accent;

        return Scaffold(
          backgroundColor: GamePalette.of(context, card.game).base,
          extendBodyBehindAppBar: true,
          appBar: GlassAppBar(
            actions: [
              IconButton(
                tooltip: viewModel.wishlisted ? 'Remove from wishlist' : 'Add to wishlist',
                onPressed: () => viewModel.wishlisted = !viewModel.wishlisted,
                icon: Icon(LucideIcons.heart, color: viewModel.wishlisted ? accent : glass.textPrimary),
              ),
              IconButton(tooltip: 'Share', onPressed: () {}, icon: Icon(LucideIcons.share2, color: glass.textPrimary)),
              const CartButton(),
              const SizedBox(width: 8),
            ],
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(child: GameBackdrop(game: card.game)),
              Builder(
                // Inside the Scaffold body, so the top padding includes the app bar
                builder: (context) => ListView(
                  padding: EdgeInsets.fromLTRB(16, GlassAppBar.contentTopPadding(context) + 12, 16, 120),
                  children: [
                    CardHero(card: card),
                    const SizedBox(height: 24),
                    FinishSelector(
                      options: market.finishes,
                      selected: viewModel.finish,
                      accent: accent,
                      onChanged: (finish) => viewModel.finish = finish,
                    ),
                    const SizedBox(height: 14),
                    PriceCard(price: card.price, market: market, accent: accent),
                    const SizedBox(height: 14),
                    OwnershipCard(
                      owned: viewModel.owned,
                      wishlisted: viewModel.wishlisted,
                      market: market,
                      accent: accent,
                      onOwnedChanged: (owned) => viewModel.owned = owned,
                      onWishlistedChanged: (wishlisted) => viewModel.wishlisted = wishlisted,
                    ),
                    const SizedBox(height: 24),
                    ListingsSection(listings: market.listings, onAdd: (listing) => _addToCart(context, card, listing)),
                    const SizedBox(height: 24),
                    CardDetailsList(card: card),
                  ],
                ),
              ),
              if (market.listings.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: BuyBar(
                    listing: market.listings.first,
                    finish: viewModel.finish,
                    accent: accent,
                    onAdd: () => _addToCart(context, card, market.listings.first),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// While the card loads (a spinner), or when it couldn't be found.
class _NoCard extends StatelessWidget {
  final bool loading;

  const _NoCard({required this.loading});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: Center(
        child: loading
            ? const CircularProgressIndicator()
            : Text('Card not found', style: TextStyle(color: context.glass.textSecondary)),
      ),
    );
  }
}
