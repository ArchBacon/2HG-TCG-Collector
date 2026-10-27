// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/domain/models/card/tcg_card.dart';

/// One line in the cart: a 2HG product (a card in a specific finish and condition), and how many.
class CartLine {
  final TcgCard card;
  final String productId; // 2HG's id of the product, for its cart
  final String finish;
  final String condition;
  final int quantity;

  const CartLine({
    required this.card,
    required this.productId,
    required this.finish,
    required this.condition,
    required this.quantity,
  });

  CartLine withQuantity(int quantity) =>
      CartLine(card: card, productId: productId, finish: finish, condition: condition, quantity: quantity);
}
