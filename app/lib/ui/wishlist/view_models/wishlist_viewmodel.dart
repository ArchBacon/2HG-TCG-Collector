// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/wishlist/wishlist_repository.dart';
import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/utils/command.dart';
import 'package:app/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// One game's wishlist, with the store status of each card.
class WishlistViewModel extends ChangeNotifier {
  WishlistViewModel({required this.tcg, required this._wishlistRepository}) {
    load = Command0(_load)..execute();
  }

  final Tcg tcg;
  final WishlistRepository _wishlistRepository;
  final _log = Logger('WishlistViewModel');

  late Command0 load;

  List<TcgCard> _cards = const [];

  List<TcgCard> get cards => _cards;

  /// Wishlisted cards that were recently added to the store.
  List<TcgCard> get newInStore => _cards.where((c) => c.isNew).toList();

  /// The cards grouped by set, keeping the order they first appear in.
  Map<String, List<TcgCard>> get bySet {
    final groups = <String, List<TcgCard>>{};
    for (final card in _cards) {
      groups.putIfAbsent(card.setName, () => []).add(card);
    }
    return groups;
  }

  Future<Result> _load() async {
    try {
      final result = await _wishlistRepository.getWishlist();
      switch (result) {
        case Ok(:final value):
          _cards = value.where((c) => c.game == tcg).toList();
        case Error(:final error):
          _log.warning('Failed to load the wishlist', error);
      }
      return result;
    } finally {
      notifyListeners();
    }
  }
}
