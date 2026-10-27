// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/tmp/shared/models/tcg.dart';

/// A card as the screens show it: what it is, plus the user's and the store's state for it.
class TcgCard {
  final String id;
  final Tcg game;
  final String name;
  final String number;
  final String? rarity;
  final String? artist; // Null = unknown
  final String? lang; // Language code from the API, e.g. "en"; null = unknown
  final String setCode;
  final String setName;
  final String? imageUrl; // Smallest card image; null = no image, show the game's cardback
  final String? mediumImageUrl; // Bigger image, for the card details page; null = no image
  final int quantity; // Wanted copies (wishlist)
  final double price; // Market price in euros
  final int owned; // Copies in the collection
  final bool wishlisted;
  final bool inStore; // For sale in the store
  final bool isNew; // Recently added to the store

  const TcgCard({
    required this.id,
    required this.game,
    required this.name,
    required this.number,
    required this.rarity,
    this.artist,
    this.lang,
    required this.setCode,
    required this.setName,
    this.imageUrl,
    this.mediumImageUrl,
    this.quantity = 1,
    required this.price,
    this.owned = 0,
    this.wishlisted = false,
    required this.inStore,
    required this.isNew,
  });

  /// This card with [owned] copies.
  TcgCard withOwned(int owned) => _copy(owned: owned);

  /// This card, on the wishlist or not.
  TcgCard withWishlisted(bool wishlisted) => _copy(wishlisted: wishlisted);

  TcgCard _copy({int? owned, bool? wishlisted}) => TcgCard(
    id: id,
    game: game,
    name: name,
    number: number,
    rarity: rarity,
    artist: artist,
    lang: lang,
    setCode: setCode,
    setName: setName,
    imageUrl: imageUrl,
    mediumImageUrl: mediumImageUrl,
    quantity: quantity,
    price: price,
    owned: owned ?? this.owned,
    wishlisted: wishlisted ?? this.wishlisted,
    inStore: inStore,
    isNew: isNew,
  );
}
