// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/wishlist/wishlist_repository.dart';
import 'package:app/data/services/local/remote_data_service.dart';
import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/utils/result.dart';
import 'package:app/utils/uuid.dart';

/// The wishlist on the API. A user can have several wishlists there; the app keeps one, made the
/// first time a card is put on it, and takes a card off all of them.
class WishlistRepositoryRemote extends WishlistRepository {
  WishlistRepositoryRemote({required this._remoteDataService});

  final RemoteDataService _remoteDataService;

  // Fetched once and shared by every caller, until the wishlist changes
  Future<Result<List<TcgCard>>>? _wishlist;

  @override
  Future<Result<List<TcgCard>>> getWishlist() => _wishlist ??= _fetchWishlist();

  Future<Result<List<TcgCard>>> _fetchWishlist() async {
    try {
      return Result.ok(await _remoteDataService.getWishlist());
    } on Exception catch (error) {
      _wishlist = null; // Try again next time
      return Result.error(error);
    }
  }

  @override
  Future<Result<void>> setWishlisted(TcgCard card, String finish, bool wishlisted) async {
    try {
      final holdings = await _remoteDataService.getWishlistHoldings(card);
      if (wishlisted) {
        if (holdings.isNotEmpty) return const Result.ok(null); // Already on it
        final ids = await _remoteDataService.getWishlistIds();
        final id = ids.firstOrNull ?? uuidV4();
        if (ids.isEmpty) await _remoteDataService.createWishlist(id, 'Wishlist');
        await _remoteDataService.changeQuantity(id, card, finish, 1, changeId: uuidV4());
      } else {
        for (final holding in holdings) {
          await _remoteDataService.changeQuantity(
            holding.collectionId,
            card,
            holding.finish,
            -holding.quantity,
            changeId: uuidV4(),
          );
        }
      }
      _wishlist = null;
      notifyListeners();
      return const Result.ok(null);
    } on Exception catch (error) {
      return Result.error(error);
    }
  }
}
