// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/cart/cart_repository.dart';
import 'package:app/data/repositories/catalog/catalog_repository.dart';
import 'package:app/data/repositories/collection/card_lists_repository.dart';
import 'package:app/data/repositories/collection/collection_repository.dart';
import 'package:app/data/repositories/market/market_repository.dart';
import 'package:app/data/repositories/wishlist/wishlist_repository.dart';
import 'package:app/domain/models/card/market_info.dart';
import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/domain/models/collection/card_collection.dart';
import 'package:app/domain/models/collection/list_kind.dart';
import 'package:app/utils/command.dart';
import 'package:app/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Card details: the card, its market data, and what the user picks on the page (finish, copies per
/// collection and per wishlist), saved as they're picked. Adds listings to the cart.
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
  final _lists = <ListKind, List<CardCollection>>{for (final kind in ListKind.values) kind: const []};
  final _holdings = <ListKind, List<CollectionHolding>>{for (final kind in ListKind.values) kind: const []};
  final _addTargetIds = <ListKind, String>{};

  /// Null while loading, or when there's no such card ([load] then has an error).
  TcgCard? get card => _card;
  MarketInfo? get market => _market;

  /// The selected finish's id (e.g. `reverse`).
  String get finish => _finish;
  set finish(String finish) => _update(() => _finish = finish);

  /// The selected finish as the screens show it.
  String get finishLabel => _market?.finishes.where((f) => f.id == _finish).firstOrNull?.label ?? _finish;

  CardListsRepository _repository(ListKind kind) => switch (kind) {
    ListKind.collection => _collectionRepository,
    ListKind.wishlist => _wishlistRepository,
  };

  /// On any of the user's wishlists, in any finish.
  bool get wishlisted => _holdings[ListKind.wishlist]!.isNotEmpty;

  /// Puts the card on the wishlist picked to add to (a copy in the selected finish), or takes it off
  /// every wishlist. Shows it right away; back to how it was when that fails. True when it worked;
  /// false too when there's no wishlist to put it on (the user then makes one).
  Future<bool> setWishlisted(bool wishlisted) async {
    final card = _card;
    if (card == null || wishlisted == this.wishlisted) return true;

    if (wishlisted) {
      final target = addTarget(ListKind.wishlist);
      return target != null && await changeQuantity(ListKind.wishlist, target.id, 1);
    }

    final before = _holdings[ListKind.wishlist]!;
    _update(() => _holdings[ListKind.wishlist] = const []);
    for (final holding in before) {
      final result = await _wishlistRepository.changeQuantity(holding.listId, card, holding.finish, -holding.quantity);
      if (result case Error(:final error)) {
        _log.warning('Failed to take card $cardId off wishlist ${holding.listId}', error);
        // Some may have gone already: show where it is now
        final now = await _wishlistRepository.getHoldings(card);
        _update(() => _holdings[ListKind.wishlist] = switch (now) {
          Ok(:final value) => value,
          Error() => before,
        });
        return false;
      }
    }
    return true;
  }

  /// The lists of [kind] holding copies of the card in the selected finish, with those copies; in
  /// the order the lists were made.
  List<(CardCollection, int)> heldIn(ListKind kind) => [
    for (final list in _lists[kind]!)
      if (_quantityIn(kind, list.id) case final quantity when quantity > 0) (list, quantity),
  ];

  /// The lists of [kind] it can be added to: those not holding it yet, in the selected finish.
  List<CardCollection> addOptions(ListKind kind) => [
    for (final list in _lists[kind]!)
      if (_quantityIn(kind, list.id) == 0) list,
  ];

  /// The list of [kind] the "add to" row adds to; null when there's none to add to (the user then
  /// makes one).
  CardCollection? addTarget(ListKind kind) {
    final options = addOptions(kind);
    return options.where((c) => c.id == _addTargetIds[kind]).firstOrNull ?? options.firstOrNull;
  }

  void setAddTarget(ListKind kind, CardCollection list) => _update(() => _addTargetIds[kind] = list.id);

  int _quantityIn(ListKind kind, String listId) => _holdings[kind]!
      .where((h) => h.listId == listId && h.finish == _finish)
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
        case Error(:final error):
          _log.warning('Failed to load card $cardId', error);
          return card;
      }

      final (market, _) = await (
        _marketRepository.getMarketInfo(card.value),
        [for (final kind in ListKind.values) _loadLists(kind, card.value)].wait,
      ).wait;

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

  /// The user's lists of [kind], and where they have [card] in them.
  Future<void> _loadLists(ListKind kind, TcgCard card) async {
    final repository = _repository(kind);
    final (lists, holdings) = await (repository.getLists(card.game), repository.getHoldings(card)).wait;
    if (lists case Ok(:final value)) _lists[kind] = value;
    if (holdings case Ok(:final value)) _holdings[kind] = value;
    for (final result in [lists, holdings]) {
      if (result case Error(:final error)) _log.warning('Failed to load the ${kind.name}s of card $cardId', error);
    }
  }

  /// Adds [delta] copies in the selected finish to a list of [kind] (negative removes). Shows the
  /// new count right away; back to the old one when it fails. True when it worked.
  Future<bool> changeQuantity(ListKind kind, String listId, int delta) async {
    final card = _card;
    if (card == null) return false;
    final finish = _finish;
    final before = _holdings[kind]!;

    _setQuantity(kind, listId, finish, _quantityIn(kind, listId) + delta);
    final result = await _repository(kind).changeQuantity(listId, card, finish, delta);
    switch (result) {
      case Ok(:final value):
        _setQuantity(kind, listId, finish, value);
        return true;
      case Error(:final error):
        _log.warning('Failed to change the copies of card $cardId in ${kind.name} $listId', error);
        _update(() => _holdings[kind] = before);
        return false;
    }
  }

  void _setQuantity(ListKind kind, String listId, String finish, int quantity) => _update(() {
    _holdings[kind] = [
      for (final h in _holdings[kind]!)
        if (h.listId != listId || h.finish != finish) h,
      if (quantity > 0) CollectionHolding(listId: listId, finish: finish, quantity: quantity),
    ];
  });

  /// Makes a list of [kind] named [name] and picks it to add to. Null when that failed.
  Future<CardCollection?> createList(ListKind kind, String name) async {
    final result = await _repository(kind).createList(name);
    switch (result) {
      case Ok(:final value):
        _update(() {
          _lists[kind] = [..._lists[kind]!, value];
          _addTargetIds[kind] = value.id;
        });
        return value;
      case Error(:final error):
        _log.warning('Failed to make ${kind.name} $name', error);
        return null;
    }
  }

  Future<Result<void>> _addToCart(StoreListing listing) async {
    final result = await _cartRepository.add(_card!, listing);
    if (result case Error(:final error)) _log.warning('Failed to add card $cardId to the cart', error);
    return result;
  }
}
