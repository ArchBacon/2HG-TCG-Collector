// Copyright 2026 Christian Delicaat. All rights reserved.

/// Market data for a card: price trend, how many collectors have / want it, and store listings.
class MarketInfo {
  final double change7d; // Price change over the last 7 days, in %
  final List<double> history; // Daily prices for the last 30 days, ending today
  final int have; // Collectors who have it
  final int want; // Collectors who want it
  final List<StoreListing> listings; // Empty = not for sale

  const MarketInfo({
    required this.change7d,
    required this.history,
    required this.have,
    required this.want,
    required this.listings,
  });
}

/// A copy of a card for sale.
class StoreListing {
  final String condition;
  final String seller;
  final double price;
  final int stock;

  const StoreListing({required this.condition, required this.seller, required this.price, required this.stock});
}
