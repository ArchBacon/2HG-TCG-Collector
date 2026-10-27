// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/domain/models/catalog/catalog_query.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/utils/result.dart';

abstract class CatalogRepository {
  /// One page of [tcg]'s cards that match [query], from page 1.
  Future<Result<CatalogPage>> getCatalogPage(Tcg tcg, CatalogQuery query, int page);

  /// The sets, rarities and artists [tcg]'s catalog can be filtered on; with [collectionId], those of
  /// the cards in that collection.
  Future<Result<CatalogFilterOptions>> getCatalogFilters(Tcg tcg, {String? collectionId});

  /// One card by id; an error when there's no such card.
  Future<Result<TcgCard>> getCard(String id);
}
