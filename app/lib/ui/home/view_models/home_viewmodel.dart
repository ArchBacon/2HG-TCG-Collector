// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/collection/collection_repository.dart';
import 'package:app/domain/models/collection/collection_summary.dart';
import 'package:app/utils/command.dart';
import 'package:app/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required this._collectionRepository,
  }) {
    load = Command0(_load)..execute();
  }

  final CollectionRepository _collectionRepository;
  final _log = Logger('HomeViewModel');
  CollectionSummary? _summary;

  late Command0 load;

  CollectionSummary? get summary => _summary;

  Future<Result> _load() async {
    try {
      final result = await _collectionRepository.getCollectionSummary();
      switch (result) {
        case Ok<CollectionSummary>():
          _summary = result.value;
          _log.fine('Loaded collection summary');
        case Error<CollectionSummary>():
          _log.warning('Failed to load collection summary', result.error);
          return result;
      }

      return result;
    } finally {
      notifyListeners();
    }
  }
}