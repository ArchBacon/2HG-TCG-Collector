// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/collection/collection_repository.dart';
import 'package:app/data/services/local/local_catalog.dart';
import 'package:app/data/services/local/local_data_service.dart';
import 'package:app/data/services/local/local_market.dart';
import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/domain/models/collection/card_collection.dart';
import 'package:app/domain/models/collection/collection_overview.dart';
import 'package:app/domain/models/collection/collection_summary.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/utils/result.dart';
import 'package:app/utils/uuid.dart';

/// Collections in memory, for while the app runs: one to start with, holding the local catalog's
/// collected cards. The overview per game stays the bundled one, whichever collection.
class CollectionRepositoryLocal extends CollectionRepository {
  CollectionRepositoryLocal({required this._localDataService}) {
    for (final tcg in Tcg.values) {
      for (final card in LocalCatalog.catalog(tcg).where((c) => c.owned > 0)) {
        _entries.add(_Entry(_firstId, card, LocalMarket.finishesFor(tcg).first.id, card.owned));
      }
    }
  }

  final LocalDataService _localDataService;

  static const _firstId = 'local-collection';
  static const _recentCount = 10;
  static const _previewCount = 3;

  final _names = <String, String>{_firstId: 'My collection'}; // In the order they were made
  final _entries = <_Entry>[]; // Oldest first

  @override
  Future<Result<CollectionSummary>> getCollectionSummary() async {
    try {
      return Result.ok(await _localDataService.getCollectionSummary());
    } on Exception catch (error) {
      return Result.error(error);
    }
  }

  @override
  Future<Result<List<CardCollection>>> getCollections(Tcg tcg) async => Result.ok([
    for (final MapEntry(key: id, value: name) in _names.entries) _collection(id, name, tcg),
  ]);

  CardCollection _collection(String id, String name, Tcg tcg) {
    final entries = _entries.where((e) => e.collectionId == id && e.card.game == tcg).toList();
    final cards = _cardsNewestFirst(entries);
    return CardCollection(
      id: id,
      name: name,
      cards: cards.length,
      copies: entries.fold(0, (n, e) => n + e.quantity),
      value: entries.fold(0.0, (sum, e) => sum + (e.card.inStore ? e.card.price * e.quantity : 0)),
      previews: cards.take(_previewCount).toList(),
    );
  }

  @override
  Future<Result<CardCollection>> createCollection(String name) async {
    final id = uuidV4();
    _names[id] = name;
    notifyListeners();
    return Result.ok(CardCollection(id: id, name: name));
  }

  @override
  Future<Result<void>> renameCollection(String collectionId, String name) async {
    if (!_names.containsKey(collectionId)) return Result.error(Exception('No collection $collectionId'));
    _names[collectionId] = name;
    notifyListeners();
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> deleteCollection(String collectionId) async {
    _names.remove(collectionId);
    _entries.removeWhere((e) => e.collectionId == collectionId);
    notifyListeners();
    return const Result.ok(null);
  }

  @override
  Future<Result<CollectionOverview>> getCollectionFor(Tcg tcg, {String? collectionId}) async {
    try {
      return Result.ok(await _localDataService.getCollectionFor(tcg));
    } on Exception catch (error) {
      return Result.error(error);
    }
  }

  @override
  Future<Result<List<TcgCard>>> getRecentlyAdded(Tcg tcg, {String? collectionId}) async {
    final entries = _entries.where((e) => e.card.game == tcg && (collectionId == null || e.collectionId == collectionId));
    return Result.ok(_cardsNewestFirst(entries.toList()).take(_recentCount).toList());
  }

  /// [tcg]'s cards in a collection, newest first, with the copies in it as `owned`. For the local
  /// catalog, which shows a collection's cards like the API does.
  List<TcgCard> cardsIn(Tcg tcg, String collectionId) =>
      _cardsNewestFirst(_entries.where((e) => e.collectionId == collectionId && e.card.game == tcg).toList());

  @override
  Future<Result<List<CollectionHolding>>> getHoldings(TcgCard card) async => Result.ok([
    for (final id in _names.keys)
      for (final entry in _entries.where((e) => e.collectionId == id && e.card.id == card.id))
        CollectionHolding(collectionId: id, finish: entry.finish, quantity: entry.quantity),
  ]);

  @override
  Future<Result<int>> changeQuantity(String collectionId, TcgCard card, String finish, int delta) async {
    if (!_names.containsKey(collectionId)) return Result.error(Exception('No collection $collectionId'));

    final index = _entries.indexWhere((e) => e.collectionId == collectionId && e.card.id == card.id && e.finish == finish);
    final quantity = ((index < 0 ? 0 : _entries[index].quantity) + delta).clamp(0, 1 << 31);
    if (index >= 0) _entries.removeAt(index);
    if (quantity > 0) _entries.add(_Entry(collectionId, card, finish, quantity)); // Newest last
    notifyListeners();
    return Result.ok(quantity);
  }

  /// The cards of [entries], newest first, once each with their copies over finishes as `owned`.
  static List<TcgCard> _cardsNewestFirst(List<_Entry> entries) {
    final owned = <String, int>{};
    final cards = <String, TcgCard>{};
    for (final entry in entries.reversed) {
      owned[entry.card.id] = (owned[entry.card.id] ?? 0) + entry.quantity;
      cards.putIfAbsent(entry.card.id, () => entry.card);
    }
    return [for (final card in cards.values) card.withOwned(owned[card.id]!)];
  }
}

/// Copies of a card in one finish in one collection.
class _Entry {
  final String collectionId;
  final TcgCard card;
  final String finish;
  final int quantity;

  const _Entry(this.collectionId, this.card, this.finish, this.quantity);
}
