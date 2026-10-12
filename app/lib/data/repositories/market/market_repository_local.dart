// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/market/market_repository.dart';
import 'package:app/data/services/local/local_data_service.dart';
import 'package:app/domain/models/card/market_info.dart';
import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/utils/result.dart';

class MarketRepositoryLocal implements MarketRepository {
  MarketRepositoryLocal({required this._localDataService});

  final LocalDataService _localDataService;

  @override
  Future<Result<MarketInfo>> getMarketInfo(TcgCard card) async {
    try {
      return Result.ok(await _localDataService.getMarketInfo(card));
    } on Exception catch (error) {
      return Result.error(error);
    }
  }
}
