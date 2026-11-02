// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/catalog/catalog_repository.dart';
import 'package:app/data/repositories/collection/collection_repository.dart';
import 'package:app/data/repositories/wishlist/wishlist_repository.dart';
import 'package:app/data/services/local/remote_data_service.dart';
import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/domain/models/catalog/catalog_query.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/utils/result.dart';

class CatalogRepositoryRemote implements CatalogRepository {
  CatalogRepositoryRemote({
    required this._remoteDataService,
    required CollectionRepository collectionRepository,
    required WishlistRepository wishlistRepository,
  }) {
    // The pages hold the user's state of each card (copies, wishlisted): fetch them again after a change
    collectionRepository.addListener(_pages.clear);
    wishlistRepository.addListener(_pages.clear);
  }

  final RemoteDataService _remoteDataService;

  // Each page (per game and query) and each game's filters are fetched once while the app runs,
  // and shared by every caller. Not a list's, nor the owned or wishlisted cards: those change.
  final _pages = <String, Future<Result<CatalogPage>>>{};
  final _filters = <Tcg, Future<Result<CatalogFilterOptions>>>{};

  @override
  Future<Result<CatalogPage>> getCatalogPage(Tcg tcg, CatalogQuery query, int page) {
    if (query.listId != null || query.owned || query.wishlisted) {
      return _fetch(() => _remoteDataService.getCatalogPage(tcg, query, page), onError: () {});
    }
    final key = Uri(path: tcg.slug, queryParameters: {...query.toParams(), 'page': '$page'}).toString();
    return _pages[key] ??= _fetch(
      () => _remoteDataService.getCatalogPage(tcg, query, page),
      onError: () => _pages.remove(key),
    );
  }

  @override
  Future<Result<CatalogFilterOptions>> getCatalogFilters(Tcg tcg, {String? listId}) => listId != null
      ? _fetch(() => _remoteDataService.getCatalogFilters(tcg, listId: listId), onError: () {})
      : _filters[tcg] ??= _fetch(() => _remoteDataService.getCatalogFilters(tcg), onError: () => _filters.remove(tcg));

  @override
  Future<Result<TcgCard>> getCard(String id) => _fetch(() => _remoteDataService.getCard(id), onError: () {});

  /// Runs [fetch] as a [Result]. On an error, [onError] drops it from the cache, so the next call
  /// tries again.
  Future<Result<T>> _fetch<T>(Future<T> Function() fetch, {required void Function() onError}) async {
    try {
      return Result.ok(await fetch());
    } on Exception catch (error) {
      onError();
      return Result.error(error);
    }
  }
}
