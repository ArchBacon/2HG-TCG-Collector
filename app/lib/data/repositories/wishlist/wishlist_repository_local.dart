// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/wishlist/wishlist_repository.dart';
import 'package:app/data/services/local/local_data_service.dart';
import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/utils/result.dart';

/// The bundled wishlist, with the cards put on or taken off while the app runs.
class WishlistRepositoryLocal extends WishlistRepository {
  WishlistRepositoryLocal({required this._localDataService});

  final LocalDataService _localDataService;

  final _added = <String, TcgCard>{}; // By id, newest last
  final _removed = <String>{};

  @override
  Future<Result<List<TcgCard>>> getWishlist() async {
    try {
      final bundled = await _localDataService.getWishlist();
      return Result.ok([
        for (final card in _added.values.toList().reversed) card.withWishlisted(true),
        for (final card in bundled)
          if (!_removed.contains(card.id) && !_added.containsKey(card.id)) card,
      ]);
    } on Exception catch (error) {
      return Result.error(error);
    }
  }

  @override
  Future<Result<void>> setWishlisted(TcgCard card, String finish, bool wishlisted) async {
    if (wishlisted) {
      _removed.remove(card.id);
      _added[card.id] = card;
    } else {
      _added.remove(card.id);
      _removed.add(card.id);
    }
    notifyListeners();
    return const Result.ok(null);
  }
}
