// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/catalog/catalog_repository.dart';
import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/utils/command.dart';
import 'package:app/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// One game's catalog. Filtering and sorting happen in the screen; they're view state.
class CatalogViewModel extends ChangeNotifier {
  CatalogViewModel({required this.tcg, required this._catalogRepository}) {
    load = Command0(_load)..execute();
  }

  final Tcg tcg;
  final CatalogRepository _catalogRepository;
  final _log = Logger('CatalogViewModel');

  late Command0 load;

  List<TcgCard> _cards = const [];

  /// Every card of the game, in set and number order.
  List<TcgCard> get cards => _cards;

  List<String> get sets => {for (final c in _cards) c.setName}.toList();
  List<String> get rarities => {for (final c in _cards) ?c.rarity}.toList();

  Future<Result> _load() async {
    try {
      final result = await _catalogRepository.getCatalog(tcg);
      switch (result) {
        case Ok(:final value):
          _cards = value;
        case Error(:final error):
          _log.warning('Failed to load the catalog of ${tcg.slug}', error);
      }
      return result;
    } finally {
      notifyListeners();
    }
  }
}
