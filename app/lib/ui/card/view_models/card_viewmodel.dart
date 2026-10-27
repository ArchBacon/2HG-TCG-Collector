// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/cart/cart_repository.dart';
import 'package:app/data/repositories/catalog/catalog_repository.dart';
import 'package:app/data/repositories/collection/collection_repository.dart';
import 'package:app/data/repositories/market/market_repository.dart';
import 'package:app/data/repositories/wishlist/wishlist_repository.dart';
import 'package:app/domain/models/card/market_info.dart';
import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/domain/models/collection/card_collection.dart';
import 'package:app/utils/command.dart';
import 'package:app/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Card details: the card, its market data, and what the user picks on the page (finish, copies per
/// collection, wishlist), saved as they're picked. Adds listings to the cart.
class CardViewModel extends ChangeNotifier {
  CardViewModel({
    required this.cardId,
    required this._catalogRepository,
    required this._marketRepository,
    required this._cartRepository,
    required this._collectionRepository,
    required this._wishlistRepository,
  }) {
    load = Command0(_load)..execute();
    addToCart = Command1(_addToCart);
  }

  final String cardId;
  final CatalogRepository _catalogRepository;
  final MarketRepository _marketRepository;
  final CartRepository _cartRepository;
  final CollectionRepository _collectionRepository;
  final WishlistRepository _wishlistRepository;
  final _log = Logger('CardViewModel');

  late Command0 load;
  late Command1<void, StoreListing> addToCart;

  TcgCard? _card;
  MarketInfo? _market;
  String _finish = '';
  bool _wishlisted = false;
  List<CardCollection> _collections = const [];
  List<CollectionHolding> _holdings = const [];
  String? _addTargetId;

  /// Null while loading, or when there's no such card ([load] then has an error).
  TcgCard? get card => _card;
  MarketInfo? get market => _market;

  /// The selected finish's id (e.g. `reverse`).
  String get finish => _finish;
  set finish(String finish) => _update(() => _finish = finish);

  /// The selected finish as the screens show it.
  String get finishLabel => _market?.finishes.where((f) => f.id == _finish).firstOrNull?.label ?? _finish;

  bool get wishlisted => _wishlisted;

  /// Puts the card on the wishlist (in the selected finish) or takes it off. Shows it right away;
  /// back to how it was when that fails. True when it worked.
  Future<bool> setWishlisted(bool wishlisted) async {
    final card = _card;
    if (card == null || wishlisted == _wishlisted) return true;

    _update(() => _wishlisted = wishlisted);
    final result = await _wishlistRepository.setWishlisted(card, _finish, wishlisted);
    if (result case Error(:final error)) {
      _log.warning('Failed to ${wishlisted ? 'wishlist' : 'unwishlist'} card $cardId', error);
      _update(() => _wishlisted = !wishlisted);
      return false;
    }
    return true;
  }

  /// The collections holding copies of the card in the selected finish, with those copies; in the
  /// order the collections were made.
  List<(CardCollection, int)> get heldIn => [
    for (final collection in _collections)
      if (_quantityIn(collection.id) case final quantity when quantity > 0) (collection, quantity),
  ];

  /// The collections it can be added to: those not holding it yet, in the selected finish.
  List<CardCollection> get addOptions => [
    for (final collection in _collections)
      if (_quantityIn(collection.id) == 0) collection,
  ];

  /// The collection the "add to collection" row adds to; null when there's none to add to (the
  /// user then makes one).
  CardCollection? get addTarget {
    final options = addOptions;
    return options.where((c) => c.id == _addTargetId).firstOrNull ?? options.firstOrNull;
  }

  set addTarget(CardCollection? collection) => _update(() => _addTargetId = collection?.id);

  int _quantityIn(String collectionId) => _holdings
      .where((h) => h.collectionId == collectionId && h.finish == _finish)
      .fold(0, (n, h) => n + h.quantity);

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
          _wishlisted = value.wishlisted;
        case Error(:final error):
          _log.warning('Failed to load card $cardId', error);
          return card;
      }

      final (market, collections, holdings) = await (
        _marketRepository.getMarketInfo(card.value),
        _collectionRepository.getCollections(card.value.game),
        _collectionRepository.getHoldings(card.value),
      ).wait;
      if (collections case Ok(:final value)) _collections = value;
      if (holdings case Ok(:final value)) _holdings = value;
      for (final result in [collections, holdings]) {
        if (result case Error(:final error)) _log.warning('Failed to load the collections of card $cardId', error);
      }

      switch (market) {
        case Ok(:final value):
          _market = value;
          _finish = value.finishes.firstOrNull?.id ?? '';
        case Error(:final error):
          _log.warning('Failed to load the market data of card $cardId', error);
      }
      return market;
    } finally {
      notifyListeners();
    }
  }

  /// Adds [delta] copies in the selected finish to a collection (negative removes). Shows the new
  /// count right away; back to the old one when it fails. True when it worked.
  Future<bool> changeQuantity(String collectionId, int delta) async {
    final card = _card;
    if (card == null) return false;
    final finish = _finish;
    final before = _holdings;

    _setQuantity(collectionId, finish, _quantityIn(collectionId) + delta);
    final result = await _collectionRepository.changeQuantity(collectionId, card, finish, delta);
    switch (result) {
      case Ok(:final value):
        _setQuantity(collectionId, finish, value);
        return true;
      case Error(:final error):
        _log.warning('Failed to change the copies of card $cardId in collection $collectionId', error);
        _update(() => _holdings = before);
        return false;
    }
  }

  void _setQuantity(String collectionId, String finish, int quantity) => _update(() {
    _holdings = [
      for (final h in _holdings)
        if (h.collectionId != collectionId || h.finish != finish) h,
      if (quantity > 0) CollectionHolding(collectionId: collectionId, finish: finish, quantity: quantity),
    ];
  });

  /// Makes a collection named [name] and picks it to add to. Null when that failed.
  Future<CardCollection?> createCollection(String name) async {
    final result = await _collectionRepository.createCollection(name);
    switch (result) {
      case Ok(:final value):
        _update(() {
          _collections = [..._collections, value];
          _addTargetId = value.id;
        });
        return value;
      case Error(:final error):
        _log.warning('Failed to make collection $name', error);
        return null;
    }
  }

  Future<Result<void>> _addToCart(StoreListing listing) async {
    final result = await _cartRepository.add(_card!, listing);
    if (result case Error(:final error)) _log.warning('Failed to add card $cardId to the cart', error);
    return result;
  }
}
