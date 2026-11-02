// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/domain/models/collection/card_collection.dart';
import 'package:app/domain/models/collection/list_kind.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/utils/result.dart';
import 'package:flutter/foundation.dart';

/// The user's lists of one [kind]: the collections or the wishlists. Both work the same, so their
/// pages are shared. Notifies its listeners whenever one changes (made, renamed, deleted, or copies
/// added or removed), so the pages showing them can reload.
abstract interface class CardListsRepository implements Listenable {
  ListKind get kind;

  /// The user's lists, oldest first, with their counts and value for [tcg].
  Future<Result<List<CardCollection>>> getLists(Tcg tcg);

  /// Makes a new, empty list.
  Future<Result<CardCollection>> createList(String name);

  Future<Result<void>> renameList(String listId, String name);

  /// Deletes a list and the cards in it.
  Future<Result<void>> deleteList(String listId);

  /// Where the user has [card] in these lists: copies per list and finish.
  Future<Result<List<CollectionHolding>>> getHoldings(TcgCard card);

  /// Adds [delta] copies of [card] in [finish] to a list (negative removes, never below 0), and
  /// returns the copies now in it.
  Future<Result<int>> changeQuantity(String listId, TcgCard card, String finish, int delta);
}
