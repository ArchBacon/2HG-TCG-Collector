// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/domain/models/collection/card_collection.dart';
import 'package:app/domain/models/collection/collection_overview.dart';
import 'package:app/domain/models/collection/collection_summary.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:flutter/foundation.dart';

import '../../../utils/result.dart';

/// The user's collections. Notifies its listeners whenever one changes (made, renamed, deleted, or
/// copies added or removed), so the pages showing them can reload.
abstract class CollectionRepository extends ChangeNotifier {
  /// Totals over all games, and per game.
  Future<Result<CollectionSummary>> getCollectionSummary();

  /// The user's collections, oldest first, with their counts and value for [tcg].
  Future<Result<List<CardCollection>>> getCollections(Tcg tcg);

  /// Makes a new, empty collection.
  Future<Result<CardCollection>> createCollection(String name);

  Future<Result<void>> renameCollection(String collectionId, String name);

  /// Deletes a collection and the cards in it.
  Future<Result<void>> deleteCollection(String collectionId);

  /// One game's collection, with progress per set: over all collections, or only [collectionId].
  Future<Result<CollectionOverview>> getCollectionFor(Tcg tcg, {String? collectionId});

  /// The cards most recently added to [tcg]'s collection (or only [collectionId]), newest first.
  Future<Result<List<TcgCard>>> getRecentlyAdded(Tcg tcg, {String? collectionId});

  /// Where the user has [card]: copies per collection and finish.
  Future<Result<List<CollectionHolding>>> getHoldings(TcgCard card);

  /// Adds [delta] copies of [card] in [finish] to a collection (negative removes, never below 0),
  /// and returns the copies now in it.
  Future<Result<int>> changeQuantity(String collectionId, TcgCard card, String finish, int delta);
}
