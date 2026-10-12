// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/cart/cart_repository.dart';
import 'package:app/data/repositories/catalog/catalog_repository.dart';
import 'package:app/data/repositories/market/market_repository.dart';
import 'package:app/domain/models/card/market_info.dart';
import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/utils/command.dart';
import 'package:app/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Card details: the card, its market data, and what the user picks on the page (finish, owned
/// copies, wishlist). Adds listings to the cart.
class CardViewModel extends ChangeNotifier {
  CardViewModel({
    required this.cardId,
    required this._catalogRepository,
    required this._marketRepository,
    required this._cartRepository,
  }) {
    load = Command0(_load)..execute();
    addToCart = Command1(_addToCart);
  }

  final String cardId;
  final CatalogRepository _catalogRepository;
  final MarketRepository _marketRepository;
  final CartRepository _cartRepository;
  final _log = Logger('CardViewModel');

  late Command0 load;
  late Command1<void, StoreListing> addToCart;

  TcgCard? _card;
  MarketInfo? _market;
  String _finish = '';
  int _owned = 0;
  bool _wishlisted = false;

  /// Null while loading, or when there's no such card ([load] then has an error).
  TcgCard? get card => _card;
  MarketInfo? get market => _market;

  // Not saved anywhere yet: reset when the page closes. TODO: save through the repositories.
  String get finish => _finish;
  int get owned => _owned;
  bool get wishlisted => _wishlisted;

  set finish(String finish) => _update(() => _finish = finish);
  set owned(int owned) => _update(() => _owned = owned);
  set wishlisted(bool wishlisted) => _update(() => _wishlisted = wishlisted);

  void _update(VoidCallback change) {
    change();
    notifyListeners();
  }

  Future<Result> _load() async {
    try {
      final card = await _catalogRepository.getCard(cardId);
      switch (card) {
        case Ok(:final value):
          _card = value;
          _owned = value.owned;
          _wishlisted = value.wishlisted;
        case Error(:final error):
          _log.warning('Failed to load card $cardId', error);
          return card;
      }

      final market = await _marketRepository.getMarketInfo(card.value);
      switch (market) {
        case Ok(:final value):
          _market = value;
          _finish = value.finishes.firstOrNull ?? '';
        case Error(:final error):
          _log.warning('Failed to load the market data of card $cardId', error);
      }
      return market;
    } finally {
      notifyListeners();
    }
  }

  Future<Result<void>> _addToCart(StoreListing listing) async {
    final result = await _cartRepository.add(_card!, finish: _finish, condition: listing.condition);
    if (result case Error(:final error)) _log.warning('Failed to add card $cardId to the cart', error);
    return result;
  }
}
