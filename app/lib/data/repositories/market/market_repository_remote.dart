// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/market/market_repository.dart';
import 'package:app/data/services/local/remote_data_service.dart';
import 'package:app/domain/models/card/market_info.dart';
import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/utils/result.dart';

// TODO: replace with API results.
class MarketRepositoryRemote implements MarketRepository {
  MarketRepositoryRemote({required this._remoteDataService});

  // ignore: unused_field
  final RemoteDataService _remoteDataService;

  @override
  Future<Result<MarketInfo>> getMarketInfo(TcgCard card) {
    // TODO: implement getMarketInfo
    throw UnimplementedError();
  }
}
