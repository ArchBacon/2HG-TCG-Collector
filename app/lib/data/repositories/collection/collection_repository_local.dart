// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/collection/collection_repository.dart';
import 'package:app/data/services/local/local_data_service.dart';
import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/domain/models/collection/collection_overview.dart';
import 'package:app/domain/models/collection/collection_summary.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/utils/result.dart';

class CollectionRepositoryLocal implements CollectionRepository {
  CollectionRepositoryLocal({required this._localDataService});

  final LocalDataService _localDataService;

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
  Future<Result<CollectionOverview>> getCollectionFor(Tcg tcg) async {
    try {
      return Result.ok(await _localDataService.getCollectionFor(tcg));
    } on Exception catch (error) {
      return Result.error(error);
    }
  }

  @override
  Future<Result<List<TcgCard>>> getRecentlyAdded(Tcg tcg) async {
    try {
      // No dates locally: the first collected cards stand in
      return Result.ok((await _localDataService.getCollectedCards(tcg)).take(_recentCount).toList());
    } on Exception catch (error) {
      return Result.error(error);
    }
  }
}
