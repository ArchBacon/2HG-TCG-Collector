// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/tmp/shared/models/tcg.dart';

/// A card as the screens show it: what it is, plus the user's and the store's state for it.
class TcgCard {
  final String id;
  final Tcg game;
  final String name;
  final String number;
  final String? rarity;
  final String setCode;
  final String setName;
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
    required this.setCode,
    required this.setName,
    this.quantity = 1,
    required this.price,
    this.owned = 0,
    this.wishlisted = false,
    required this.inStore,
    required this.isNew,
  });
}
