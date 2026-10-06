// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/collection/collection_repository.dart';
import 'package:app/domain/models/collection/collection_overview.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/utils/command.dart';
import 'package:app/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

class OverviewViewModel extends ChangeNotifier {
  OverviewViewModel({
    required this.tcg,
    required this._collectionRepository,
  }) {
    load = Command0(_load)..execute();
  }

  final Tcg tcg;
  final CollectionRepository _collectionRepository;
  final _log = Logger('overviewViewModel');
  CollectionOverview? _overview;

  late Command0 load;

  CollectionOverview? get overview => _overview;

  Future<Result> _load() async {
    try {
      final result = await _collectionRepository.getCollectionFor(tcg);
      switch (result) {
        case Ok<CollectionOverview>():
          _overview = result.value;
          _log.fine('Loaded collection ${tcg.slug} overview');
        case Error<CollectionOverview>():
          _log.warning('Failed to load collection ${tcg.slug} overview', result.error);
          return result;
      }

      return result;
    } finally {
      notifyListeners();
    }
  }
}
