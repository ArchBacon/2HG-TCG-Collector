// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/collection/collection_repository.dart';
import 'package:app/data/services/local/remote_data_service.dart';
import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/domain/models/collection/card_collection.dart';
import 'package:app/domain/models/collection/collection_overview.dart';
import 'package:app/domain/models/collection/collection_summary.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/utils/result.dart';
import 'package:app/utils/uuid.dart';

class CollectionRepositoryRemote extends CollectionRepository {
  CollectionRepositoryRemote({required this._remoteDataService});

  final RemoteDataService _remoteDataService;

  // Fetched once and shared by every caller, until a collection changes
  Future<Result<CollectionSummary>>? _summary;
  final _overviews = <(Tcg, String?), Future<Result<CollectionOverview>>>{};
  final _recentlyAdded = <(Tcg, String?), Future<Result<List<TcgCard>>>>{};

  @override
  Future<Result<CollectionSummary>> getCollectionSummary() =>
      _summary ??= _fetch(_remoteDataService.getCollectionSummary, onError: () => _summary = null);

  @override
  Future<Result<List<CardCollection>>> getCollections(Tcg tcg) => _run(() => _remoteDataService.getCollections(tcg));

  @override
  Future<Result<CardCollection>> createCollection(String name) =>
      _change(() => _remoteDataService.createCollection(uuidV4(), name));

  @override
  Future<Result<void>> renameCollection(String collectionId, String name) =>
      _change(() => _remoteDataService.renameCollection(collectionId, name));

  @override
  Future<Result<void>> deleteCollection(String collectionId) =>
      _change(() => _remoteDataService.deleteCollection(collectionId));

  @override
  Future<Result<CollectionOverview>> getCollectionFor(Tcg tcg, {String? collectionId}) =>
      _overviews[(tcg, collectionId)] ??= _fetch(
        () => _remoteDataService.getCollectionFor(tcg, collectionId: collectionId),
        onError: () => _overviews.remove((tcg, collectionId)),
      );

  @override
  Future<Result<List<TcgCard>>> getRecentlyAdded(Tcg tcg, {String? collectionId}) =>
      _recentlyAdded[(tcg, collectionId)] ??= _fetch(
        () => _remoteDataService.getRecentlyAdded(tcg, collectionId: collectionId),
        onError: () => _recentlyAdded.remove((tcg, collectionId)),
      );

  @override
  Future<Result<List<CollectionHolding>>> getHoldings(TcgCard card) => _run(() => _remoteDataService.getHoldings(card));

  @override
  Future<Result<int>> changeQuantity(String collectionId, TcgCard card, String finish, int delta) =>
      _change(() => _remoteDataService.changeQuantity(collectionId, card, finish, delta, changeId: uuidV4()));

  /// Runs [fetch] as a [Result]. On an error, [onError] drops it from the cache, so the next call
  /// tries again.
  Future<Result<T>> _fetch<T>(Future<T> Function() fetch, {required void Function() onError}) async {
    final result = await _run(fetch);
    if (result is Error) onError();
    return result;
  }

  /// Runs [change] as a [Result]; when it worked, forgets what was cached and tells the listeners.
  Future<Result<T>> _change<T>(Future<T> Function() change) async {
    final result = await _run(change);
    if (result is Ok) {
      _summary = null;
      _overviews.clear();
      _recentlyAdded.clear();
      notifyListeners();
    }
    return result;
  }

  Future<Result<T>> _run<T>(Future<T> Function() call) async {
    try {
      return Result.ok(await call());
    } on Exception catch (error) {
      return Result.error(error);
    }
  }
}
