// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/collection/collection_repository.dart';
import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/domain/models/collection/collection_overview.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/utils/command.dart';
import 'package:app/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// One game's collection: totals, progress per set, and the cards added last.
class CollectionViewModel extends ChangeNotifier {
  CollectionViewModel({required this.tcg, required this._collectionRepository}) {
    load = Command0(_load)..execute();
  }

  final Tcg tcg;
  final CollectionRepository _collectionRepository;
  final _log = Logger('CollectionViewModel');

  late Command0 load;

  CollectionOverview? _overview;
  List<TcgCard> _recentlyAdded = const [];

  /// Null while loading.
  CollectionOverview? get overview => _overview;

  /// Every set, across the blocks.
  List<CollectionOverviewSet> get sets => [for (final block in _overview?.blocks ?? const <CollectionOverviewBlock>[]) ...block.sets];

  List<TcgCard> get recentlyAdded => _recentlyAdded;

  Future<Result> _load() async {
    try {
      final overview = await _collectionRepository.getCollectionFor(tcg);
      switch (overview) {
        case Ok(:final value):
          _overview = value;
        case Error(:final error):
          _log.warning('Failed to load the collection of ${tcg.slug}', error);
          return overview;
      }

      final recent = await _collectionRepository.getRecentlyAdded(tcg);
      switch (recent) {
        case Ok(:final value):
          _recentlyAdded = value;
        case Error(:final error):
          _log.warning('Failed to load the recently added cards of ${tcg.slug}', error);
      }
      return recent;
    } finally {
      notifyListeners();
    }
  }
}
