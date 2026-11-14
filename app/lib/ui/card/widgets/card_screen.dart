// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/domain/models/card/market_info.dart';
import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/domain/models/collection/list_kind.dart';
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
import 'package:app/ui/collection/widgets/collection_dialogs.dart';
import 'package:app/ui/shared/glass/game_backdrop.dart';
import 'package:app/ui/shared/glass/header_controls.dart';
import 'package:app/ui/shared/glass_app_bar.dart';
import 'package:flutter/material.dart';

/// Card details, full screen over the nav bar. Collection and shop in one place: the card, your
/// copies per collection and wishlist, the 2HG listings to buy it from, then its price trend, with an "Add
/// to cart" bar at the bottom. Borrows from Discogs: community have/want counts, and the marketplace
/// listings right on the item page.
class CardScreen extends StatelessWidget {
  final CardViewModel viewModel;

  const CardScreen({super.key, required this.viewModel});

  Future<void> _changeQuantity(BuildContext context, ListKind kind, String listId, int delta) async {
    if (await viewModel.changeQuantity(kind, listId, delta) || !context.mounted) return;
    _showMessage(context, "Couldn't update the ${kind.name}");
  }

  /// Asks for a name and makes a list of [kind] to add to; with [addCopy], with a copy in it right
  /// away.
  Future<void> _newList(BuildContext context, ListKind kind, Color accent, {required bool addCopy}) async {
    final name = await showCollectionNameDialog(context, kind: kind, accent: accent);
    if (name == null || !context.mounted) return;
    final list = await viewModel.createList(kind, name);
    if (!context.mounted) return;
    if (list == null) {
      _showMessage(context, "Couldn't make the ${kind.name}");
    } else if (addCopy) {
      await _changeQuantity(context, kind, list.id, 1);
    }
  }

  ListRows _listRows(BuildContext context, ListKind kind, Color accent) => ListRows(
    kind: kind,
    heldIn: viewModel.heldIn(kind),
    addOptions: viewModel.addOptions(kind),
    addTarget: viewModel.addTarget(kind),
    onChange: (listId, delta) => _changeQuantity(context, kind, listId, delta),
    onPickAddTarget: (list) => viewModel.setAddTarget(kind, list),
    onNewList: (addCopy) => _newList(context, kind, accent, addCopy: addCopy),
  );

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 96), // Above the buy bar
        content: Text(message),
      ));
  }

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

        final accent = GamePalette.of(context, card.game).accent;

        return Scaffold(
          backgroundColor: GamePalette.of(context, card.game).base,
          extendBodyBehindAppBar: true,
          appBar: GlassAppBar(
            actions: const [
              CartButton(),
              SizedBox(width: 8),
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
                    OwnershipCard(
                      collections: _listRows(context, ListKind.collection, accent),
                      wishlists: _listRows(context, ListKind.wishlist, accent),
                      market: market,
                      accent: accent,
                    ),
                    const SizedBox(height: 24),
                    ListingsSection(listings: market.listings, onAdd: (listing) => _addToCart(context, card, listing)),
                    const SizedBox(height: 14),
                    PriceCard(market: market, finish: viewModel.finish, finishLabel: viewModel.finishLabel),
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
                    finish: market.listings.first.finish,
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
