// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/services/mock/mock_cart.dart';
import 'package:app/data/services/mock/mock_data.dart';
import 'package:app/data/services/mock/mock_market.dart';
import 'package:app/domain/models/card/market_info.dart';
import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/themes/game_palette.dart';
import 'package:app/themes/glass_theme.dart';
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
class CardScreen extends StatefulWidget {
  final String cardId;

  const CardScreen({super.key, required this.cardId});

  @override
  State<CardScreen> createState() => _CardScreenState();
}

class _CardScreenState extends State<CardScreen> {
  late final TcgCard? _card = MockData.card(widget.cardId);
  late final MarketInfo? _market = _card == null ? null : MockMarket.forCard(_card);
  late final List<String> _finishes = _card == null ? const [] : MockMarket.finishesFor(_card.game);

  // Not saved anywhere yet: resets when the page closes
  late String _finish = _finishes.isEmpty ? '' : _finishes.first;
  late int _owned = _card?.owned ?? 0;
  late bool _wishlisted = _card?.wishlisted ?? false;

  void _addToCart(TcgCard card, StoreListing listing) {
    addToCart(card, finish: _finish, condition: listing.condition);
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
    final card = _card;
    final market = _market;
    if (card == null || market == null) return const _CardNotFound();

    final glass = context.glass;
    final accent = GamePalette.of(context, card.game).accent;

    return Scaffold(
      backgroundColor: GamePalette.of(context, card.game).base,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        actions: [
          IconButton(
            tooltip: _wishlisted ? 'Remove from wishlist' : 'Add to wishlist',
            onPressed: () => setState(() => _wishlisted = !_wishlisted),
            icon: Icon(LucideIcons.heart, color: _wishlisted ? accent : glass.textPrimary),
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
                  options: _finishes,
                  selected: _finish,
                  accent: accent,
                  onChanged: (finish) => setState(() => _finish = finish),
                ),
                const SizedBox(height: 14),
                PriceCard(price: card.price, market: market, accent: accent),
                const SizedBox(height: 14),
                OwnershipCard(
                  owned: _owned,
                  wishlisted: _wishlisted,
                  market: market,
                  accent: accent,
                  onOwnedChanged: (owned) => setState(() => _owned = owned),
                  onWishlistedChanged: (wishlisted) => setState(() => _wishlisted = wishlisted),
                ),
                const SizedBox(height: 24),
                ListingsSection(listings: market.listings, onAdd: (listing) => _addToCart(card, listing)),
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
                finish: _finish,
                accent: accent,
                onAdd: () => _addToCart(card, market.listings.first),
              ),
            ),
        ],
      ),
    );
  }
}

class _CardNotFound extends StatelessWidget {
  const _CardNotFound();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: Center(child: Text('Card not found', style: TextStyle(color: context.glass.textSecondary))),
    );
  }
}
