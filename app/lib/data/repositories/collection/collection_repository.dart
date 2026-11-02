// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/collection/card_lists_repository.dart';
import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/domain/models/collection/collection_overview.dart';
import 'package:app/domain/models/collection/collection_summary.dart';
import 'package:app/domain/models/collection/list_kind.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:flutter/foundation.dart';

import '../../../utils/result.dart';

/// The user's collections, plus what's only for collections: totals, progress per set, and the
/// cards added last.
abstract class CollectionRepository extends ChangeNotifier implements CardListsRepository {
  @override
  ListKind get kind => ListKind.collection;

  /// Totals over all games, and per game.
  Future<Result<CollectionSummary>> getCollectionSummary();

  /// One game's collection, with progress per set: over all collections, or only [collectionId].
  Future<Result<CollectionOverview>> getCollectionFor(Tcg tcg, {String? collectionId});

  /// The cards most recently added to [tcg]'s collection (or only [collectionId]), newest first.
  Future<Result<List<TcgCard>>> getRecentlyAdded(Tcg tcg, {String? collectionId});
}
