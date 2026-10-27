// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/collection/collection_repository.dart';
import 'package:app/domain/models/collection/card_collection.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/utils/command.dart';
import 'package:app/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// One collection: its name, to rename it, and to delete it. Its cards are a catalog of their own
/// (CatalogViewModel). Reloads when a collection changes anywhere in the app.
class CollectionViewModel extends ChangeNotifier {
  CollectionViewModel({required this.tcg, required this.collectionId, required this._collectionRepository}) {
    load = Command0(_load)..execute();
    rename = Command1(_rename);
    delete = Command0(_delete);
    _collectionRepository.addListener(_reload);
  }

  final Tcg tcg;
  final String collectionId;
  final CollectionRepository _collectionRepository;
  final _log = Logger('CollectionViewModel');

  late Command0 load;
  late Command1<void, String> rename;
  late Command0<void> delete;

  CardCollection? _collection;
  bool _deleted = false;

  /// Null while loading, or when there's no such collection (any more).
  CardCollection? get collection => _collection;

  void _reload() {
    if (!_deleted) load.execute();
  }

  Future<Result> _load() async {
    final result = await _collectionRepository.getCollections(tcg);
    switch (result) {
      case Ok(:final value):
        _collection = value.where((c) => c.id == collectionId).firstOrNull;
      case Error(:final error):
        _log.warning('Failed to load collection $collectionId', error);
    }
    notifyListeners();
    return result;
  }

  Future<Result<void>> _rename(String name) async {
    final result = await _collectionRepository.renameCollection(collectionId, name);
    if (result case Error(:final error)) _log.warning('Failed to rename collection $collectionId', error);
    return result;
  }

  Future<Result<void>> _delete() async {
    _deleted = true; // No reloading the collection that's going
    final result = await _collectionRepository.deleteCollection(collectionId);
    if (result case Error(:final error)) {
      _deleted = false;
      _log.warning('Failed to delete collection $collectionId', error);
    }
    return result;
  }

  @override
  void dispose() {
    _collectionRepository.removeListener(_reload);
    super.dispose();
  }
}
