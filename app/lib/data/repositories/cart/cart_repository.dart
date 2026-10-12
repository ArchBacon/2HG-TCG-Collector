// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/domain/models/cart/cart_line.dart';
import 'package:app/utils/result.dart';
import 'package:flutter/foundation.dart';

/// The cart. Unlike the other repositories it holds state the whole app shows (e.g. the item count
/// on the cart button), so it notifies its listeners whenever the lines change.
abstract class CartRepository extends ChangeNotifier {
  /// The lines as last loaded or changed.
  List<CartLine> get lines;

  /// Number of items: the quantities added up.
  int get itemCount => lines.fold(0, (n, line) => n + line.quantity);

  /// (Re)loads the lines.
  Future<Result<void>> load();

  /// Adds one copy of [card] in [finish] and [condition] as a new line.
  Future<Result<void>> add(TcgCard card, {required String finish, required String condition});

  /// Sets a line's quantity; 0 removes the line.
  Future<Result<void>> setQuantity(CartLine line, int quantity);
}
