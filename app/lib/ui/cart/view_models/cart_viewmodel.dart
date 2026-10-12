// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/cart/cart_repository.dart';
import 'package:app/domain/models/cart/cart_line.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/utils/command.dart';
import 'package:app/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// The cart: its lines per game, totals and shipping. Follows the cart repository, so changes made
/// elsewhere (e.g. "Add to cart" on a card) show up.
class CartViewModel extends ChangeNotifier {
  CartViewModel({required this._cartRepository}) {
    _cartRepository.addListener(notifyListeners);
    load = Command0(_load)..execute();
    setQuantity = Command1(_setQuantity);
  }

  final CartRepository _cartRepository;
  final _log = Logger('CartViewModel');

  late Command0 load;
  late Command1<void, (CartLine, int)> setQuantity;

  static const freeShippingFrom = 50.0;
  static const _shippingCost = 4.95;

  List<CartLine> get lines => _cartRepository.lines;
  int get itemCount => _cartRepository.itemCount;
  double get subtotal => lines.fold(0.0, (sum, l) => sum + l.card.price * l.quantity);
  double get shipping => subtotal >= freeShippingFrom || lines.isEmpty ? 0 : _shippingCost;
  double get total => subtotal + shipping;

  /// The lines grouped per game (a cart can mix games).
  Map<Tcg, List<CartLine>> get linesByGame {
    final groups = <Tcg, List<CartLine>>{};
    for (final line in lines) {
      groups.putIfAbsent(line.card.game, () => []).add(line);
    }
    return groups;
  }

  Future<Result> _load() async {
    final result = await _cartRepository.load();
    if (result case Error(:final error)) _log.warning('Failed to load the cart', error);
    return result;
  }

  Future<Result<void>> _setQuantity((CartLine, int) change) async {
    final (line, quantity) = change;
    final result = await _cartRepository.setQuantity(line, quantity);
    if (result case Error(:final error)) _log.warning('Failed to change the cart', error);
    return result;
  }

  @override
  void dispose() {
    _cartRepository.removeListener(notifyListeners);
    super.dispose();
  }
}
