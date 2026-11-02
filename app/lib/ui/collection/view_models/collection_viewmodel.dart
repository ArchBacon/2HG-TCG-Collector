// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/collection/card_lists_repository.dart';
import 'package:app/domain/models/collection/card_collection.dart';
import 'package:app/domain/models/collection/list_kind.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/utils/command.dart';
import 'package:app/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// One collection or wishlist: its name, to rename it, and to delete it. Its cards are a catalog of
/// their own (CatalogViewModel). Reloads when a list of its kind changes anywhere in the app.
class CollectionViewModel extends ChangeNotifier {
  CollectionViewModel({required this.tcg, required this.collectionId, required this._listsRepository}) {
    load = Command0(_load)..execute();
    rename = Command1(_rename);
    delete = Command0(_delete);
    _listsRepository.addListener(_reload);
  }

  final Tcg tcg;
  final String collectionId;
  final CardListsRepository _listsRepository;
  final _log = Logger('CollectionViewModel');

  late Command0 load;
  late Command1<void, String> rename;
  late Command0<void> delete;

  CardCollection? _collection;
  bool _deleted = false;

  ListKind get kind => _listsRepository.kind;

  /// Null while loading, or when there's no such list (any more).
  CardCollection? get collection => _collection;

  void _reload() {
    if (!_deleted) load.execute();
  }

  Future<Result> _load() async {
    final result = await _listsRepository.getLists(tcg);
    switch (result) {
      case Ok(:final value):
        _collection = value.where((c) => c.id == collectionId).firstOrNull;
      case Error(:final error):
        _log.warning('Failed to load ${kind.name} $collectionId', error);
    }
    notifyListeners();
    return result;
  }

  Future<Result<void>> _rename(String name) async {
    final result = await _listsRepository.renameList(collectionId, name);
    if (result case Error(:final error)) _log.warning('Failed to rename ${kind.name} $collectionId', error);
    return result;
  }

  Future<Result<void>> _delete() async {
    _deleted = true; // No reloading the list that's going
    final result = await _listsRepository.deleteList(collectionId);
    if (result case Error(:final error)) {
      _deleted = false;
      _log.warning('Failed to delete ${kind.name} $collectionId', error);
    }
    return result;
  }

  @override
  void dispose() {
    _listsRepository.removeListener(_reload);
    super.dispose();
  }
}
