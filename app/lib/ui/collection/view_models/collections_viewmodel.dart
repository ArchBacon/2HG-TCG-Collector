// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/collection/collection_repository.dart';
import 'package:app/domain/models/collection/card_collection.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/utils/command.dart';
import 'package:app/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Collection tab: the user's collections, with their counts and value for one game. Reloads when
/// a collection changes anywhere in the app.
class CollectionsViewModel extends ChangeNotifier {
  CollectionsViewModel({required this.tcg, required this._collectionRepository}) {
    load = Command0(_load)..execute();
    create = Command1(_create);
    _collectionRepository.addListener(_reload);
  }

  final Tcg tcg;
  final CollectionRepository _collectionRepository;
  final _log = Logger('CollectionsViewModel');

  late Command0 load;
  late Command1<CardCollection, String> create;

  List<CardCollection>? _collections;

  /// Null while loading for the first time.
  List<CardCollection>? get collections => _collections;

  void _reload() => load.execute();

  Future<Result> _load() async {
    final result = await _collectionRepository.getCollections(tcg);
    switch (result) {
      case Ok(:final value):
        _collections = value;
      case Error(:final error):
        _log.warning('Failed to load the collections', error);
    }
    notifyListeners();
    return result;
  }

  /// Makes a collection named [name]; the list reloads through the repository.
  Future<Result<CardCollection>> _create(String name) async {
    final result = await _collectionRepository.createCollection(name);
    if (result case Error(:final error)) _log.warning('Failed to make collection $name', error);
    return result;
  }

  @override
  void dispose() {
    _collectionRepository.removeListener(_reload);
    super.dispose();
  }
}
