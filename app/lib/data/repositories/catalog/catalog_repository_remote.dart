// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/catalog/catalog_repository.dart';
import 'package:app/data/services/local/remote_data_service.dart';
import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/utils/result.dart';

// TODO: replace with API results.
class CatalogRepositoryRemote implements CatalogRepository {
  CatalogRepositoryRemote({required this._remoteDataService});

  // ignore: unused_field
  final RemoteDataService _remoteDataService;

  @override
  Future<Result<List<TcgCard>>> getCatalog(Tcg tcg) {
    // TODO: implement getCatalog
    throw UnimplementedError();
  }

  @override
  Future<Result<TcgCard>> getCard(String id) {
    // TODO: implement getCard
    throw UnimplementedError();
  }
}
