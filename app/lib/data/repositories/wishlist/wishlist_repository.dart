// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/utils/result.dart';

abstract class WishlistRepository {
  /// The wishlisted cards of every game, with their store status.
  Future<Result<List<TcgCard>>> getWishlist();
}
