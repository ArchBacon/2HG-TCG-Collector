// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/wishlist/wishlist_repository.dart';
import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/utils/command.dart';
import 'package:app/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// The cards of one game on any of the user's wishlists that just came into the store, for the
/// Wishlist tab. Reloads when a wishlist changes.
class WishlistViewModel extends ChangeNotifier {
  WishlistViewModel({required this.tcg, required this._wishlistRepository}) {
    load = Command0(_load)..execute();
    _wishlistRepository.addListener(_reload);
  }

  final Tcg tcg;
  final WishlistRepository _wishlistRepository;
  final _log = Logger('WishlistViewModel');

  late Command0 load;

  List<TcgCard> _newInStore = const [];
  bool _disposed = false;

  /// Wishlisted cards that were recently added to the store.
  List<TcgCard> get newInStore => _newInStore;

  void _reload() => load.execute();

  Future<Result> _load() async {
    final result = await _wishlistRepository.getWishlist();
    if (_disposed) return result;
    switch (result) {
      case Ok(:final value):
        _newInStore = value.where((c) => c.game == tcg && c.isNew).toList();
      case Error(:final error):
        _log.warning('Failed to load the wishlist', error);
    }
    notifyListeners();
    return result;
  }

  @override
  void dispose() {
    _disposed = true;
    _wishlistRepository.removeListener(_reload);
    super.dispose();
  }
}
