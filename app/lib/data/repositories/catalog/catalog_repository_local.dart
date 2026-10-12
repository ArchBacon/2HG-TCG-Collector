// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/catalog/catalog_repository.dart';
import 'package:app/data/services/local/local_data_service.dart';
import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/utils/result.dart';

class CatalogRepositoryLocal implements CatalogRepository {
  CatalogRepositoryLocal({required this._localDataService});

  final LocalDataService _localDataService;

  @override
  Future<Result<List<TcgCard>>> getCatalog(Tcg tcg) async {
    try {
      return Result.ok(await _localDataService.getCatalog(tcg));
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
