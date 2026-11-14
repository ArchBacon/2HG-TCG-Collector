// Copyright 2026 Christian Delicaat. All rights reserved.

/// Market data for a card: the finishes it comes in, its market prices, how many collectors have /
/// want it, and store listings.
class MarketInfo {
  final List<CardFinish> finishes;
  final List<MarketPrice> prices; // Empty = no market price (some games' card data has none)
  final int have; // Collectors who have it
  final int want; // Collectors who want it
  final List<StoreListing> listings; // Empty = not for sale

  const MarketInfo({
    required this.finishes,
    required this.prices,
    required this.have,
    required this.want,
    required this.listings,
  });

  /// The market prices of the finish with the API's id [finish], one per source.
  List<MarketPrice> pricesFor(String finish) => [for (final price in prices) if (price.finish == finish) price];
}

/// Where a market price is from.
enum PriceSource {
  cardmarket('Cardmarket', 'Trend'),
  tcgplayer('TCGplayer', 'Market price');

  const PriceSource(this.label, this.kind);

  final String label;

  /// Which of the source's prices it is.
  final String kind;
}

/// A card's market price at a [source], for one finish, in the source's own [currency] (ISO 4217:
/// `EUR` for Cardmarket, `USD` for TCGplayer); nothing is converted.
class MarketPrice {
  final PriceSource source;
  final String finish; // The API's id of the finish, e.g. `foil`
  final String currency;
  final double price;
  final DateTime updatedAt; // When the source last updated it, as far as the card data says

  const MarketPrice({
    required this.source,
    required this.finish,
    required this.currency,
    required this.price,
    required this.updatedAt,
  });
}

/// A finish a card comes in: the API's name for it ([id], e.g. `reverse`), and how the screens show
/// it ([label], e.g. "Reverse Holo").
class CardFinish {
  final String id;
  final String label;

  const CardFinish(this.id, this.label);
}

/// A copy of a card for sale at 2HG, the only store.
class StoreListing {
  final String productId; // 2HG's id of the product: what its cart takes
  final String finish; // As the screens show it, e.g. "Foil"
  final String condition; // As the shop names it (its cart takes it like this), e.g. "Near Mint" or "played"
  final double price;
  final int stock;

  const StoreListing({
    required this.productId,
    required this.finish,
    required this.condition,
    required this.price,
    required this.stock,
  });
}
