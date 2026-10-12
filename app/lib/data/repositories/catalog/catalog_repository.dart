// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/utils/result.dart';

abstract class CatalogRepository {
  /// Every card of [tcg], in set and number order.
  Future<Result<List<TcgCard>>> getCatalog(Tcg tcg);

  /// One card by id; an error when there's no such card.
  Future<Result<TcgCard>> getCard(String id);
}
