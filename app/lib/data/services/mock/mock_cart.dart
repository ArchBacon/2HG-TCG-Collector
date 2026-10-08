// Copyright 2026 Christian Delicaat. All rights reserved.

// Mock cart state until there's a cart repository.

import 'package:app/data/services/mock/mock_data.dart';
import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/domain/models/cart/cart_line.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:flutter/foundation.dart';

/// The cart. Starts with a few cards from different games, so it isn't empty on first look.
final cart = ValueNotifier<List<CartLine>>([
  CartLine(card: MockData.catalog(Tcg.pokemon)[5], finish: 'Holofoil', condition: 'Near Mint', quantity: 1),
  CartLine(card: MockData.catalog(Tcg.pokemon)[21], finish: 'Normal', condition: 'Near Mint', quantity: 3),
  CartLine(card: MockData.catalog(Tcg.onePiece)[9], finish: 'Normal', condition: 'Lightly Played', quantity: 1),
  CartLine(card: MockData.catalog(Tcg.lorcana)[14], finish: 'Foil', condition: 'Near Mint', quantity: 2),
]);

void addToCart(TcgCard card, {required String finish, String condition = 'Near Mint'}) {
  cart.value = [...cart.value, CartLine(card: card, finish: finish, condition: condition, quantity: 1)];
}

/// Sets a line's quantity; 0 removes the line.
void setCartQuantity(CartLine line, int quantity) {
  final lines = [...cart.value];
  final index = lines.indexOf(line);
  if (index < 0) return;
  if (quantity <= 0) {
    lines.removeAt(index);
  } else {
    lines[index] = line.withQuantity(quantity);
  }
  cart.value = lines;
}
