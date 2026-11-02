// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/collection/card_lists_repository.dart';
import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/domain/models/collection/list_kind.dart';
import 'package:flutter/foundation.dart';
import 'package:app/utils/result.dart';

/// The user's wishlists, plus the cards on any of them merged into one (for what came into the
/// store).
abstract class WishlistRepository extends ChangeNotifier implements CardListsRepository {
  @override
  ListKind get kind => ListKind.wishlist;

  /// The cards on any of the user's wishlists, of every game, with their store status.
  Future<Result<List<TcgCard>>> getWishlist();
}
