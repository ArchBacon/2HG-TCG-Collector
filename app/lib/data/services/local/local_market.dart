// Copyright 2026 Christian Delicaat. All rights reserved.

// The local market data: there's no store or price data in the app, so it's generated. Made up,
// but stable per card (seeded by the card id), apart from the date of the prices.

import 'dart:math';

import 'package:app/domain/models/card/market_info.dart';
import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/tmp/shared/models/tcg.dart';

abstract final class LocalMarket {
  static MarketInfo forCard(TcgCard card) {
    final random = Random(card.id.hashCode);
    final have = 200 + random.nextInt(4000);
    final want = 40 + random.nextInt(900);

    // Around the card's price, per finish (a foil or holo for more): Cardmarket in EUR and
    // TCGplayer in USD, as the API gives them, except for the games whose card data has none
    final finishes = finishesFor(card.game);
    final today = DateTime.now();
    final prices = !card.game.hasMarketPrices
        ? const <MarketPrice>[]
        : [
            for (final (i, finish) in finishes.indexed)
              for (final (source, currency, rate) in [(PriceSource.cardmarket, 'EUR', 1.0), (PriceSource.tcgplayer, 'USD', 1.15)])
                if (source != PriceSource.cardmarket || card.game != Tcg.onePiece)
                  MarketPrice(
                    source: source,
                    finish: finish.id,
                    currency: currency,
                    price: card.price * (1 + i * 1.5) * rate * (0.85 + random.nextDouble() * 0.3),
                    updatedAt: today,
                  ),
          ];

    return MarketInfo(
      finishes: finishes,
      prices: prices,
      have: have,
      want: want,
      listings: !card.inStore
          ? const []
          : [
              StoreListing(
                productId: '${card.id}-1',
                finish: finishes.first.label,
                condition: 'Near Mint',
                price: card.price,
                stock: 1 + random.nextInt(4),
              ),
              StoreListing(
                productId: '${card.id}-2',
                finish: finishes.first.label,
                condition: 'Lightly Played',
                price: card.price * 0.82,
                stock: 2,
              ),
            ],
    );
  }

  /// The finishes of [game]'s cards, with the API's ids.
  static List<CardFinish> finishesFor(Tcg game) => switch (game) {
    Tcg.pokemon => const [CardFinish('normal', 'Normal'), CardFinish('holo', 'Holo'), CardFinish('reverse', 'Reverse Holo')],
    Tcg.mtg => const [CardFinish('nonfoil', 'Normal'), CardFinish('foil', 'Foil')],
    _ => const [CardFinish('normal', 'Normal'), CardFinish('foil', 'Foil')],
  };
}
