// Copyright 2026 Christian Delicaat. All rights reserved.

import 'dart:async';

import 'package:app/data/repositories/catalog/catalog_repository.dart';
import 'package:app/data/repositories/collection/collection_repository.dart';
import 'package:app/data/repositories/wishlist/wishlist_repository.dart';
import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/domain/models/catalog/catalog_query.dart';
import 'package:app/domain/models/collection/list_kind.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/ui/catalog/widgets/catalog_filter_bar.dart';
import 'package:app/ui/shared/app_state.dart';
import 'package:app/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// One game's catalog, a page at a time; or, with [listId], the cards in that collection or
/// wishlist ([listKind]); or, with [listSearch], the cards in any of the user's lists of [listKind],
/// found by the search (none before something is typed). Filters, sorting and the search in the
/// header ([search]) are applied by the repository: changing one loads the first page again, and
/// [loadMore] adds the next.
///
/// The whole catalog also has the cards the user added to their collections last; the others load
/// their cards again when a collection or wishlist changes.
class CatalogViewModel extends ChangeNotifier {
  CatalogViewModel({
    required this.tcg,
    this.listId,
    this.listKind = ListKind.collection,
    this.listSearch = false,
    required this._catalogRepository,
    required this._collectionRepository,
    required this._wishlistRepository,
  }) {
    search.addListener(_onSearchChanged);
    _collectionRepository.addListener(_onListsChanged);
    // A list's cards show the copies owned and whether they're wishlisted, so either can change them
    if (!_isCatalog) _wishlistRepository.addListener(_onListsChanged);
    _loadFilterOptions();
    _reload();
    if (_isCatalog) _loadRecentlyAdded();
  }

  final Tcg tcg;
  final String? listId;
  final ListKind listKind;
  final bool listSearch;

  bool get _isCatalog => listId == null && !listSearch;

  /// The header's search: the catalog's, shared by the tabs ([cardSearch]); the others' their own.
  late final ValueNotifier<String> search = _isCatalog ? cardSearch : ValueNotifier('');
  final CatalogRepository _catalogRepository;
  final CollectionRepository _collectionRepository;
  final WishlistRepository _wishlistRepository;
  final _log = Logger('CatalogViewModel');

  List<TcgCard> _recentlyAdded = const [];

  CatalogFilters _filters = const CatalogFilters();
  CatalogSort _sort = CatalogSort.number;
  CatalogFilterOptions _options = const CatalogFilterOptions(sets: [], rarities: [], artists: []);

  List<TcgCard> _cards = const [];
  int _page = 0; // Pages loaded so far
  int _total = 0;
  bool _hasMore = false;
  bool _loading = false;
  bool _loadingMore = false;
  bool _failed = false;
  int _generation = 0; // Bumped on every reload, so pages of an older query are dropped
  Timer? _searchDebounce;
  bool _disposed = false;

  /// The cards added to the user's collections last, newest first; none for a list.
  List<TcgCard> get recentlyAdded => _recentlyAdded;

  CatalogFilters get filters => _filters;
  CatalogSort get sort => _sort;

  /// Set names, rarities and artists to filter on.
  List<String> get sets => [for (final set in _options.sets) set.name];
  List<String> get rarities => _options.rarities;
  List<String> get artists => _options.artists;

  /// The cards loaded so far, of every page.
  List<TcgCard> get cards => _cards;

  /// Cards that match, over all pages.
  int get total => _total;

  /// Loading the first page (after opening, or a change to the filters, sort or search).
  bool get loading => _loading;

  /// Loading the next page.
  bool get loadingMore => _loadingMore;

  /// The last page failed to load.
  bool get failed => _failed;

  set filters(CatalogFilters filters) {
    _filters = filters;
    _reload();
  }

  set sort(CatalogSort sort) {
    _sort = sort;
    _reload();
  }

  CatalogQuery get _query => CatalogQuery(
    setCode: _options.sets.where((s) => s.name == _filters.set).firstOrNull?.code,
    rarity: _filters.rarity,
    artist: _filters.artist,
    owned: (listSearch && listKind == ListKind.collection) || _filters.owned,
    wishlisted: (listSearch && listKind == ListKind.wishlist) || _filters.wishlisted,
    inStore: _filters.inStore,
    search: search.value.trim(),
    sort: _sort,
    listId: listId,
  );

  /// Loads the next page, unless it's already loading or there is none.
  void loadMore() {
    if (_loading || _loadingMore || !_hasMore) return;
    _loadingMore = true;
    notifyListeners();
    _loadPage(_page + 1);
  }

  // Wait for a pause in typing, instead of loading for every letter
  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), _reload);
  }

  void _reload() {
    _generation++;
    _cards = const [];
    _page = 0;
    _total = 0;
    _hasMore = false;
    _loading = true;
    _loadingMore = false;
    notifyListeners();
    if (listSearch && search.value.trim().isEmpty) {
      _loading = false; // Nothing to find before something is typed
      notifyListeners();
      return;
    }
    _loadPage(1);
  }

  Future<void> _loadPage(int page) async {
    final generation = _generation;
    final result = await _catalogRepository.getCatalogPage(tcg, _query, page);
    if (_disposed || generation != _generation) return; // Closed, or for an older query

    switch (result) {
      case Ok(:final value):
        _cards = page == 1 ? value.cards : [..._cards, ...value.cards];
        _page = page;
        _total = value.total;
        _hasMore = value.hasMore;
        _failed = false;
      case Error(:final error):
        _log.warning('Failed to load page $page of the catalog of ${tcg.slug}', error);
        _failed = true;
    }
    _loading = false;
    _loadingMore = false;
    notifyListeners();
  }

  void _onListsChanged() {
    if (_isCatalog) {
      _loadRecentlyAdded();
    } else {
      // Copies were added or removed: what's in it, and so what it can be filtered on
      _loadFilterOptions();
      _reload();
    }
  }

  Future<void> _loadRecentlyAdded() async {
    final result = await _collectionRepository.getRecentlyAdded(tcg);
    if (_disposed) return;
    switch (result) {
      case Ok(:final value):
        _recentlyAdded = value;
        notifyListeners();
      case Error(:final error):
        _log.warning('Failed to load the recently added cards of ${tcg.slug}', error);
    }
  }

  Future<void> _loadFilterOptions() async {
    final result = await _catalogRepository.getCatalogFilters(tcg, listId: listId);
    if (_disposed) return;
    switch (result) {
      case Ok(:final value):
        _options = value;
        notifyListeners();
      case Error(:final error):
        _log.warning('Failed to load the catalog filters of ${tcg.slug}', error);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    search.removeListener(_onSearchChanged);
    if (!_isCatalog) search.dispose(); // Its own
    _collectionRepository.removeListener(_onListsChanged);
    _wishlistRepository.removeListener(_onListsChanged);
    _searchDebounce?.cancel();
    super.dispose();
  }
}
