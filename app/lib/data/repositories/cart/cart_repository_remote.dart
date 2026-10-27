// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/cart/cart_repository.dart';
import 'package:app/domain/models/card/market_info.dart';
import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/domain/models/cart/cart_line.dart';
import 'package:app/utils/result.dart';

/// Cart kept in the app only, in memory (lost when the app closes). Starts empty.
class CartRepositoryRemote extends CartRepository {
  var _lines = <CartLine>[];

  @override
  List<CartLine> get lines => _lines;

  @override
  Future<Result<void>> load() async => const Result.ok(null); // Nothing to fetch: the lines live here

  @override
  Future<Result<void>> add(TcgCard card, StoreListing listing) async {
    _lines = [
      ..._lines,
      CartLine(
        card: card,
        productId: listing.productId,
        finish: listing.finish,
        condition: listing.condition,
        quantity: 1,
      ),
    ];
    notifyListeners();
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> setQuantity(CartLine line, int quantity) async {
    final index = _lines.indexOf(line);
    if (index < 0) return Result.error(Exception('Line not in the cart'));
    _lines = [..._lines];
    if (quantity <= 0) {
      _lines.removeAt(index);
    } else {
      _lines[index] = line.withQuantity(quantity);
    }
    notifyListeners();
    return const Result.ok(null);
  }
}
