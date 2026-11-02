// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/domain/models/card/tcg_card.dart';

/// The catalog's sort orders.
enum CatalogSort {
  number('Number'), // Set order (newest set first), then number
  priceHigh('Price: high to low'),
  priceLow('Price: low to high'),
  name('Name');

  const CatalogSort(this.label);
  final String label;
}

/// Which of a game's cards to show, and in what order.
class CatalogQuery {
  final String? setCode; // Null = all sets
  final String? rarity; // Null = all rarities
  final String? artist; // Null = all artists
  final bool owned;
  final bool wishlisted;
  final bool inStore;
  final String search; // Part of the name; empty = any
  final CatalogSort sort;
  final String? listId; // Only the cards in this collection or wishlist (for a collection, `owned` being the copies in it); null = all cards

  const CatalogQuery({
    this.setCode,
    this.rarity,
    this.artist,
    this.owned = false,
    this.wishlisted = false,
    this.inStore = false,
    this.search = '',
    this.sort = CatalogSort.number,
    this.listId,
  });

  bool matches(TcgCard card) =>
      (setCode == null || card.setCode == setCode) &&
      (rarity == null || card.rarity == rarity) &&
      (artist == null || card.artist == artist) &&
      (!owned || card.owned > 0) &&
      (!wishlisted || card.wishlisted) &&
      (!inStore || card.inStore) &&
      (search.isEmpty || card.name.toLowerCase().contains(search.toLowerCase()));

  /// As the API's query parameters; only the ones that are set.
  Map<String, String> toParams() => {
    'set': ?setCode,
    'rarity': ?rarity,
    'artist': ?artist,
    if (owned) 'owned': '1',
    if (wishlisted) 'wishlisted': '1',
    if (inStore) 'inStore': '1',
    if (search.isNotEmpty) 'search': search,
    if (sort != CatalogSort.number) 'sort': sort.name,
    'list': ?listId,
  };
}

/// One page of a catalog query's cards.
class CatalogPage {
  final List<TcgCard> cards;
  final int total; // Cards matching the query, over all pages
  final int page; // From 1
  final int perPage;

  const CatalogPage({required this.cards, required this.total, required this.page, required this.perPage});

  bool get hasMore => page * perPage < total;
}

/// What a game's catalog can be filtered on.
class CatalogFilterOptions {
  final List<({String code, String name})> sets; // Newest first
  final List<String> rarities;
  final List<String> artists; // A to Z

  const CatalogFilterOptions({required this.sets, required this.rarities, required this.artists});
}
