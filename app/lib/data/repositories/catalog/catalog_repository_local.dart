// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/catalog/catalog_repository.dart';
import 'package:app/data/repositories/collection/collection_repository_local.dart';
import 'package:app/data/services/local/local_data_service.dart';
import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/domain/models/catalog/catalog_query.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/utils/result.dart';

class CatalogRepositoryLocal implements CatalogRepository {
  CatalogRepositoryLocal({required this._localDataService, required this._collectionRepository});

  final LocalDataService _localDataService;
  final CollectionRepositoryLocal _collectionRepository; // For a collection's cards

  static const _perPage = 30; // Like the API

  /// Filters, sorts and pages the whole local catalog, the way the API does.
  @override
  Future<Result<CatalogPage>> getCatalogPage(Tcg tcg, CatalogQuery query, int page) async {
    try {
      final collectionId = query.collectionId;
      final all = collectionId == null ? await _localDataService.getCatalog(tcg) : _collectionRepository.cardsIn(tcg, collectionId);
      final cards = all.where(query.matches).toList();
      switch (query.sort) {
        case CatalogSort.number:
          break; // Already in set/number order
        case CatalogSort.priceHigh:
          cards.sort((a, b) => b.price.compareTo(a.price));
        case CatalogSort.priceLow:
          cards.sort((a, b) => a.price.compareTo(b.price));
        case CatalogSort.name:
          cards.sort((a, b) => a.name.compareTo(b.name));
      }
      return Result.ok(
        CatalogPage(
          cards: cards.skip((page - 1) * _perPage).take(_perPage).toList(),
          total: cards.length,
          page: page,
          perPage: _perPage,
        ),
      );
    } on Exception catch (error) {
      return Result.error(error);
    }
  }

  @override
  Future<Result<CatalogFilterOptions>> getCatalogFilters(Tcg tcg, {String? collectionId}) async {
    try {
      final cards = collectionId == null ? await _localDataService.getCatalog(tcg) : _collectionRepository.cardsIn(tcg, collectionId);
      return Result.ok(
        CatalogFilterOptions(
          sets: {for (final c in cards) (code: c.setCode, name: c.setName)}.toList(),
          rarities: {for (final c in cards) ?c.rarity}.toList(),
          artists: {for (final c in cards) ?c.artist}.toList()..sort(),
        ),
      );
    } on Exception catch (error) {
      return Result.error(error);
    }
  }

  @override
  Future<Result<TcgCard>> getCard(String id) async {
    try {
      final card = await _localDataService.getCard(id);
      return card == null ? Result.error(Exception('No card with id $id')) : Result.ok(card);
    } on Exception catch (error) {
      return Result.error(error);
    }
  }
}
