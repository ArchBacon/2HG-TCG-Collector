// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/domain/models/card/tcg_card.dart';
import 'package:flutter/foundation.dart';
import 'package:app/utils/result.dart';

/// The user's wishlist. Notifies its listeners when a card is put on it or taken off, so the pages
/// showing it can reload.
abstract class WishlistRepository extends ChangeNotifier {
  /// The wishlisted cards of every game, with their store status.
  Future<Result<List<TcgCard>>> getWishlist();

  /// Puts [card] on the wishlist (in [finish]), or takes it off (in every finish).
  Future<Result<void>> setWishlisted(TcgCard card, String finish, bool wishlisted);
}
