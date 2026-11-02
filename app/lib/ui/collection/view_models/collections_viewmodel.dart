// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/collection/card_lists_repository.dart';
import 'package:app/domain/models/collection/card_collection.dart';
import 'package:app/domain/models/collection/list_kind.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/utils/command.dart';
import 'package:app/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Collection or Wishlist tab: the user's lists of one [kind], with their counts and value for one
/// game. Reloads when one changes anywhere in the app.
class CollectionsViewModel extends ChangeNotifier {
  CollectionsViewModel({required this.tcg, required this._listsRepository}) {
    load = Command0(_load)..execute();
    create = Command1(_create);
    _listsRepository.addListener(_reload);
  }

  final Tcg tcg;
  final CardListsRepository _listsRepository;
  final _log = Logger('CollectionsViewModel');

  late Command0 load;
  late Command1<CardCollection, String> create;

  List<CardCollection>? _collections;

  ListKind get kind => _listsRepository.kind;

  /// Null while loading for the first time.
  List<CardCollection>? get collections => _collections;

  void _reload() => load.execute();

  Future<Result> _load() async {
    final result = await _listsRepository.getLists(tcg);
    switch (result) {
      case Ok(:final value):
        _collections = value;
      case Error(:final error):
        _log.warning('Failed to load the ${kind.name}s', error);
    }
    notifyListeners();
    return result;
  }

  /// Makes a list named [name]; the lists reload through the repository.
  Future<Result<CardCollection>> _create(String name) async {
    final result = await _listsRepository.createList(name);
    if (result case Error(:final error)) _log.warning('Failed to make ${kind.name} $name', error);
    return result;
  }

  @override
  void dispose() {
    _listsRepository.removeListener(_reload);
    super.dispose();
  }
}
