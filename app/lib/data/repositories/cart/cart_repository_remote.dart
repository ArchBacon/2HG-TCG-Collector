// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/cart/cart_repository.dart';
import 'package:app/data/services/local/remote_data_service.dart';
import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/domain/models/cart/cart_line.dart';
import 'package:app/utils/result.dart';

// TODO: replace with API results. Keep [lines] up to date and call notifyListeners() after changes,
// so the cart button's count follows.
class CartRepositoryRemote extends CartRepository {
  CartRepositoryRemote({required this._remoteDataService});

  // ignore: unused_field
  final RemoteDataService _remoteDataService;

  @override
  List<CartLine> get lines => const [];

  @override
  Future<Result<void>> load() {
    // TODO: implement load
    throw UnimplementedError();
  }

  @override
  Future<Result<void>> add(TcgCard card, {required String finish, required String condition}) {
    // TODO: implement add
    throw UnimplementedError();
  }

  @override
  Future<Result<void>> setQuantity(CartLine line, int quantity) {
    // TODO: implement setQuantity
    throw UnimplementedError();
  }
}
