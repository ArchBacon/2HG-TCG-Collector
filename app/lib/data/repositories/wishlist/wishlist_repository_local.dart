// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/collection/local_lists.dart';
import 'package:app/data/repositories/wishlist/wishlist_repository.dart';
import 'package:app/data/services/local/local_catalog.dart';
import 'package:app/data/services/local/local_market.dart';
import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/domain/models/collection/card_collection.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/utils/result.dart';

/// Wishlists in memory, for while the app runs: one to start with, holding the local catalog's
/// wishlisted cards.
class WishlistRepositoryLocal extends WishlistRepository {
  WishlistRepositoryLocal() {
    for (final tcg in Tcg.values) {
      for (final card in LocalCatalog.catalog(tcg).where((c) => c.wishlisted)) {
        _lists.seed(card, LocalMarket.finishesFor(tcg).first.id, 1);
      }
    }
  }

  late final _lists = LocalLists(firstId: 'local-wishlist', firstName: 'My Wishlist', onChange: notifyListeners);

  @override
  Future<Result<List<TcgCard>>> getWishlist() async => Result.ok([for (final tcg in Tcg.values) ...cardsIn(tcg)]);

  @override
  Future<Result<List<CardCollection>>> getLists(Tcg tcg) async => _lists.getLists(tcg);

  @override
  Future<Result<CardCollection>> createList(String name) async => _lists.createList(name);

  @override
  Future<Result<void>> renameList(String listId, String name) async => _lists.renameList(listId, name);

  @override
  Future<Result<void>> deleteList(String listId) async => _lists.deleteList(listId);

  /// Whether [listId] is one of the wishlists.
  bool has(String listId) => _lists.has(listId);

  /// [tcg]'s cards on a wishlist (or on any), newest first. For the local catalog, which shows a
  /// wishlist's cards like the API does.
  List<TcgCard> cardsIn(Tcg tcg, {String? wishlistId}) => [
    for (final (card, _) in _lists.cardsIn(tcg, listId: wishlistId)) card.withWishlisted(true),
  ];

  @override
  Future<Result<List<CollectionHolding>>> getHoldings(TcgCard card) async => _lists.getHoldings(card);

  @override
  Future<Result<int>> changeQuantity(String listId, TcgCard card, String finish, int delta) async =>
      _lists.changeQuantity(listId, card, finish, delta);
}
