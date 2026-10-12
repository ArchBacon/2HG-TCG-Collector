// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/domain/models/card/market_info.dart';
import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/utils/result.dart';

abstract class MarketRepository {
  /// Finishes, price trend, have/want counts and store listings for [card].
  Future<Result<MarketInfo>> getMarketInfo(TcgCard card);
}
