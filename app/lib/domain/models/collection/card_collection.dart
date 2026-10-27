// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/domain/models/card/tcg_card.dart';

/// A collection the user made, as the Collection tab shows it: its counts and value for one game,
/// and the cards added to it last. A collection can hold cards of every game.
class CardCollection {
  final String id;
  final String name;
  final int cards; // Different cards of the game
  final int copies; // Copies of them, over finishes
  final double value; // Store prices of the cards in stock, times their copies
  final List<TcgCard> previews; // Added last, newest first; at most 3

  const CardCollection({
    required this.id,
    required this.name,
    this.cards = 0,
    this.copies = 0,
    this.value = 0,
    this.previews = const [],
  });
}

/// Copies of a card in one of the user's collections, in one finish.
class CollectionHolding {
  final String collectionId;
  final String finish; // The API's name for it, e.g. `reverse`
  final int quantity;

  const CollectionHolding({required this.collectionId, required this.finish, required this.quantity});
}
