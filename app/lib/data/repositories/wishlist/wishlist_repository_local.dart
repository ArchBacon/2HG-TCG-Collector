// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/wishlist/wishlist_repository.dart';
import 'package:app/data/services/local/local_data_service.dart';
import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/utils/result.dart';

class WishlistRepositoryLocal implements WishlistRepository {
  WishlistRepositoryLocal({required this._localDataService});

  final LocalDataService _localDataService;

  @override
  Future<Result<List<TcgCard>>> getWishlist() async {
    try {
      return Result.ok(await _localDataService.getWishlist());
    } on Exception catch (error) {
      return Result.error(error);
    }
  }
}
