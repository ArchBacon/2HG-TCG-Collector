// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/collection/collection_repository.dart';
import 'package:app/data/services/local/local_data_service.dart';
import 'package:app/domain/models/collection/collection_overview.dart';
import 'package:app/domain/models/collection/collection_summary.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/utils/result.dart';


class CollectionRepositoryLocal implements CollectionRepository {
  CollectionRepositoryLocal({required this._localDataService});

  final LocalDataService _localDataService;

  @override
  Future<Result<CollectionSummary>> getCollectionSummary() async {
    try {
      final collectionSummary = (await _localDataService.getCollectionSummary());

      return Result.ok(collectionSummary);
    } on Exception catch (error) {
      return Result.error(error);
    }
  }

  @override
  Future<Result<CollectionOverview>> getCollectionFor(Tcg tcg) async {
    try {
      final collectionOverview = (await _localDataService.getCollectionFor(tcg));

      return Result.ok(collectionOverview);
    } on Exception catch (error) {
      return Result.error(error);
    }
  }
}