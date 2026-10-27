// Copyright 2026 Christian Delicaat. All rights reserved.

/// Market data for a card: the finishes it comes in, price trend, how many collectors have / want
/// it, and store listings.
class MarketInfo {
  final List<CardFinish> finishes;
  final double change7d; // Price change over the last 7 days, in %
  final List<double> history; // Daily prices for the last 30 days, ending today
  final int have; // Collectors who have it
  final int want; // Collectors who want it
  final List<StoreListing> listings; // Empty = not for sale

  const MarketInfo({
    required this.finishes,
    required this.change7d,
    required this.history,
    required this.have,
    required this.want,
    required this.listings,
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
