// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/wishlist/wishlist_repository.dart';
import 'package:app/data/services/local/remote_data_service.dart';
import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/domain/models/collection/card_collection.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/utils/result.dart';
import 'package:app/utils/uuid.dart';

class WishlistRepositoryRemote extends WishlistRepository {
  WishlistRepositoryRemote({required this._remoteDataService});

  final RemoteDataService _remoteDataService;

  // Fetched once and shared by every caller, until a wishlist changes
  Future<Result<List<TcgCard>>>? _wishlist;

  @override
  Future<Result<List<TcgCard>>> getWishlist() => _wishlist ??= _fetchWishlist();

  Future<Result<List<TcgCard>>> _fetchWishlist() async {
    final result = await _run(_remoteDataService.getWishlist);
    if (result is Error) _wishlist = null; // Try again next time
    return result;
  }

  @override
  Future<Result<List<CardCollection>>> getLists(Tcg tcg) => _run(() => _remoteDataService.getLists(kind, tcg));

  @override
  Future<Result<CardCollection>> createList(String name) =>
      _change(() => _remoteDataService.createList(kind, uuidV4(), name));

  @override
  Future<Result<void>> renameList(String listId, String name) =>
      _change(() => _remoteDataService.renameList(listId, name));

  @override
  Future<Result<void>> deleteList(String listId) => _change(() => _remoteDataService.deleteList(listId));

  @override
  Future<Result<List<CollectionHolding>>> getHoldings(TcgCard card) => _run(() => _remoteDataService.getHoldings(kind, card));

  @override
  Future<Result<int>> changeQuantity(String listId, TcgCard card, String finish, int delta) =>
      _change(() => _remoteDataService.changeQuantity(listId, card, finish, delta, changeId: uuidV4()));

  /// Runs [change] as a [Result]; when it worked, forgets what was cached and tells the listeners.
  Future<Result<T>> _change<T>(Future<T> Function() change) async {
    final result = await _run(change);
    if (result is Ok) {
      _wishlist = null;
      notifyListeners();
    }
    return result;
  }

  Future<Result<T>> _run<T>(Future<T> Function() call) async {
    try {
      return Result.ok(await call());
    } on Exception catch (error) {
      return Result.error(error);
    }
  }
}
