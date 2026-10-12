// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/cart/cart_repository.dart';
import 'package:app/data/services/local/local_data_service.dart';
import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/domain/models/cart/cart_line.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/utils/result.dart';

/// Cart in memory only (lost when the app closes). Starts with a few cards from different games, so
/// it isn't empty on first look.
class CartRepositoryLocal extends CartRepository {
  CartRepositoryLocal({required this._localDataService});

  final LocalDataService _localDataService;

  var _lines = <CartLine>[];
  Future<Result<void>>? _loading; // Shared by every caller: the cart is only filled once

  @override
  List<CartLine> get lines => _lines;

  @override
  Future<Result<void>> load() => _loading ??= _load();

  Future<Result<void>> _load() async {
    try {
      final pokemon = await _localDataService.getCatalog(Tcg.pokemon);
      final onePiece = await _localDataService.getCatalog(Tcg.onePiece);
      final lorcana = await _localDataService.getCatalog(Tcg.lorcana);
      _lines = [
        CartLine(card: pokemon[5], finish: 'Holofoil', condition: 'Near Mint', quantity: 1),
        CartLine(card: pokemon[21], finish: 'Normal', condition: 'Near Mint', quantity: 3),
        CartLine(card: onePiece[9], finish: 'Normal', condition: 'Lightly Played', quantity: 1),
        CartLine(card: lorcana[14], finish: 'Foil', condition: 'Near Mint', quantity: 2),
      ];
      notifyListeners();
      return const Result.ok(null);
    } on Exception catch (error) {
      _loading = null; // Try again next time
      return Result.error(error);
    }
  }

  @override
  Future<Result<void>> add(TcgCard card, {required String finish, required String condition}) async {
    _lines = [..._lines, CartLine(card: card, finish: finish, condition: condition, quantity: 1)];
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
