// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/domain/models/collection/collection_overview.dart';
import 'package:app/domain/models/collection/collection_summary.dart';
import 'package:app/tmp/shared/models/tcg.dart';

import '../../../utils/result.dart';

abstract class CollectionRepository {
  /// Totals over all games, and per game.
  Future<Result<CollectionSummary>> getCollectionSummary();

  /// One game's collection, with progress per set.
  Future<Result<CollectionOverview>> getCollectionFor(Tcg tcg);

  /// The cards most recently added to [tcg]'s collection, newest first.
  Future<Result<List<TcgCard>>> getRecentlyAdded(Tcg tcg);
}
