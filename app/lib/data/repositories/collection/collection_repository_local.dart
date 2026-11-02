// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/collection/collection_repository.dart';
import 'package:app/data/repositories/collection/local_lists.dart';
import 'package:app/data/services/local/local_catalog.dart';
import 'package:app/data/services/local/local_data_service.dart';
import 'package:app/data/services/local/local_market.dart';
import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/domain/models/collection/card_collection.dart';
import 'package:app/domain/models/collection/collection_overview.dart';
import 'package:app/domain/models/collection/collection_summary.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/utils/result.dart';

/// Collections in memory, for while the app runs: one to start with, holding the local catalog's
/// collected cards. The overview per game stays the bundled one, whichever collection.
class CollectionRepositoryLocal extends CollectionRepository {
  CollectionRepositoryLocal({required this._localDataService}) {
    for (final tcg in Tcg.values) {
      for (final card in LocalCatalog.catalog(tcg).where((c) => c.owned > 0)) {
        _lists.seed(card, LocalMarket.finishesFor(tcg).first.id, card.owned);
      }
    }
  }

  final LocalDataService _localDataService;
  late final _lists = LocalLists(firstId: 'local-collection', firstName: 'My Collection', onChange: notifyListeners);

  static const _recentCount = 10;

  @override
  Future<Result<CollectionSummary>> getCollectionSummary() async {
    try {
      return Result.ok(await _localDataService.getCollectionSummary());
    } on Exception catch (error) {
      return Result.error(error);
    }
  }

  @override
  Future<Result<List<CardCollection>>> getLists(Tcg tcg) async => _lists.getLists(tcg);

  @override
  Future<Result<CardCollection>> createList(String name) async => _lists.createList(name);

  @override
  Future<Result<void>> renameList(String listId, String name) async => _lists.renameList(listId, name);

  @override
  Future<Result<void>> deleteList(String listId) async => _lists.deleteList(listId);

  @override
  Future<Result<CollectionOverview>> getCollectionFor(Tcg tcg, {String? collectionId}) async {
    try {
      return Result.ok(await _localDataService.getCollectionFor(tcg));
    } on Exception catch (error) {
      return Result.error(error);
    }
  }

  @override
  Future<Result<List<TcgCard>>> getRecentlyAdded(Tcg tcg, {String? collectionId}) async =>
      Result.ok(cardsIn(tcg, collectionId: collectionId).take(_recentCount).toList());

  /// Whether [listId] is one of the collections.
  bool has(String listId) => _lists.has(listId);

  /// [tcg]'s cards in a collection (or in any), newest first, with the copies in it as `owned`. For
  /// the local catalog, which shows a collection's cards like the API does.
  List<TcgCard> cardsIn(Tcg tcg, {String? collectionId}) => [
    for (final (card, copies) in _lists.cardsIn(tcg, listId: collectionId)) card.withOwned(copies),
  ];

  @override
  Future<Result<List<CollectionHolding>>> getHoldings(TcgCard card) async => _lists.getHoldings(card);

  @override
  Future<Result<int>> changeQuantity(String listId, TcgCard card, String finish, int delta) async =>
      _lists.changeQuantity(listId, card, finish, delta);
}
