// Copyright 2026 Christian Delicaat. All rights reserved.

// Mock market data until there's a store / price API. Made up, but stable per card (seeded by
// the card id).

import 'dart:math';

import 'package:app/domain/models/card/market_info.dart';
import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/tmp/shared/models/tcg.dart';

abstract final class MockMarket {
  static MarketInfo forCard(TcgCard card) {
    final random = Random(card.id.hashCode);
    final change = random.nextDouble() * 18 - 6; // Mostly up
    final have = 200 + random.nextInt(4000);
    final want = 40 + random.nextInt(900);

    // 30 days of prices, ending at today's price, moving by roughly the change overall
    final start = card.price / (1 + change / 100);
    final history = [
      for (var i = 0; i < 30; i++) start + (card.price - start) * (i / 29) + (random.nextDouble() - 0.5) * card.price * 0.06,
    ]..[29] = card.price;

    return MarketInfo(
      change7d: change,
      history: history,
      have: have,
      want: want,
      listings: !card.inStore
          ? const []
          : [
              StoreListing(condition: 'Near Mint', seller: 'TCG Collector Store', price: card.price, stock: 1 + random.nextInt(4)),
              StoreListing(condition: 'Near Mint', seller: 'Partner seller', price: card.price * 1.06, stock: 1),
              StoreListing(condition: 'Lightly Played', seller: 'TCG Collector Store', price: card.price * 0.82, stock: 2),
            ],
    );
  }

  /// The finishes a card can come in, per game.
  static List<String> finishesFor(Tcg game) => switch (game) {
    Tcg.pokemon => const ['Normal', 'Holofoil', 'Reverse Holo'],
    Tcg.mtg => const ['Nonfoil', 'Foil'],
    _ => const ['Normal', 'Foil'],
  };
}
