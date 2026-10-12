// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/collection/collection_repository.dart';
import 'package:app/data/repositories/wishlist/wishlist_repository.dart';
import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/domain/models/collection/collection_summary.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/utils/command.dart';
import 'package:app/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// The start screen: collection totals over all games and per game, and the wishlist (for the
/// "N new" counts on the game tiles).
class StartViewModel extends ChangeNotifier {
  StartViewModel({required this._collectionRepository, required this._wishlistRepository}) {
    load = Command0(_load)..execute();
  }

  final CollectionRepository _collectionRepository;
  final WishlistRepository _wishlistRepository;
  final _log = Logger('StartViewModel');

  late Command0 load;

  CollectionSummary? _summary;
  List<TcgCard> _wishlist = const [];

  int get collected => _summary?.total.collected ?? 0;
  int get wishlisted => _summary?.total.wishlisted ?? 0;

  /// This game's part of the collection; null while loading or when there are no cards.
  CollectionSummaryTcg? collectionFor(Tcg game) => _summary?.tcgs[game.slug];

  /// Wishlisted cards of [game] that were recently added to the store.
  int newInStoreFor(Tcg game) => _wishlist.where((c) => c.game == game && c.isNew).length;

  Future<Result> _load() async {
    try {
      final summary = await _collectionRepository.getCollectionSummary();
      switch (summary) {
        case Ok(:final value):
          _summary = value;
        case Error(:final error):
          _log.warning('Failed to load the collection summary', error);
          return summary;
      }

      final wishlist = await _wishlistRepository.getWishlist();
      switch (wishlist) {
        case Ok(:final value):
          _wishlist = value;
        case Error(:final error):
          _log.warning('Failed to load the wishlist', error);
      }
      return wishlist;
    } finally {
      notifyListeners();
    }
  }
}
