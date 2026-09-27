// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/collection/collection_repository.dart';
import 'package:app/data/services/local/remote_data_service.dart';
import 'package:app/domain/models/collection/collection.dart';
import 'package:app/utils/result.dart';

// TODO: replace with API results.
class CollectionRepositoryRemote implements CollectionRepository {
  CollectionRepositoryRemote({required this._remoteDataService});

  final RemoteDataService _remoteDataService;

  @override
  Future<Result<CollectionSummary>> getCollectionSummary() async {
    try {
      final collectionSummary = (await _remoteDataService.getCollectionSummary());

      return Result.ok(collectionSummary);
    } on Exception catch (error) {
      return Result.error(error);
    }
  }
}