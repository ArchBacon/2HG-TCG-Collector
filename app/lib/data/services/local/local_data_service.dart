// Copyright 2026 Christian Delicaat. All rights reserved.

import 'dart:convert';

import 'package:app/config/assets.dart';
import 'package:app/data/services/local/local_catalog.dart';
import 'package:app/data/services/local/local_market.dart';
import 'package:app/domain/models/card/market_info.dart';
import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/domain/models/collection/collection_overview.dart';
import 'package:app/domain/models/collection/collection_summary.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:flutter/services.dart';

/// Data bundled with the app: JSON files in assets/data/, and generated data where there are no
/// files (catalog and market, see LocalCatalog and LocalMarket).
class LocalDataService {
  Future<CollectionSummary> getCollectionSummary() async {
    final json = await _loadStringAsset(Assets.collectionSummary);
    return CollectionSummary.fromJson(json);
  }

  Future<CollectionOverview> getCollectionFor(Tcg tcg) async {
    final json = await _loadStringAsset(Assets.collectionFor(tcg));
    return CollectionOverview.fromJson(json);
  }

  /// Cards in the collection, as the catalog has them; the first ones stand in for "recently added".
  Future<List<TcgCard>> getCollectedCards(Tcg tcg) async => LocalCatalog.catalog(tcg).where((c) => c.owned > 0).toList();

  /// The wishlist of every game.
  Future<List<TcgCard>> getWishlist() async {
    final json = await _loadStringAsset(Assets.wishlist);
    final tcgs = json['tcgs'] as Map<String, dynamic>;
    return [
      for (final group in tcgs.values)
        for (final entry in (group as Map<String, dynamic>)['entries'] as List) _parseWishlistEntry(entry as Map<String, dynamic>),
    ];
  }

  Future<List<TcgCard>> getCatalog(Tcg tcg) async => LocalCatalog.catalog(tcg);

  /// A card by id, from any game's catalog or the wishlist. Null when there's no such card.
  Future<TcgCard?> getCard(String id) async {
    for (final tcg in Tcg.values) {
      final card = LocalCatalog.catalog(tcg).where((c) => c.id == id).firstOrNull;
      if (card != null) return card;
    }
    return (await getWishlist()).where((c) => c.id == id).firstOrNull;
  }

  Future<MarketInfo> getMarketInfo(TcgCard card) async => LocalMarket.forCard(card);

  TcgCard _parseWishlistEntry(Map<String, dynamic> entry) {
    final card = entry['card'] as Map<String, dynamic>;
    final set = card['set'] as Map<String, dynamic>;
    return TcgCard(
      id: card['id'] as String,
      game: Tcg.values.firstWhere((t) => t.slug == card['tcg']),
      name: card['name'] as String,
      number: card['number'] as String,
      rarity: card['rarity'] as String?,
      setCode: set['code'] as String,
      setName: set['name'] as String,
      quantity: entry['quantity'] as int,
      price: (entry['price'] as num).toDouble(),
      wishlisted: true,
      inStore: entry['inStore'] as bool,
      isNew: entry['isNew'] as bool,
    );
  }

  Future<Map<String, dynamic>> _loadStringAsset(String asset) async {
    final localData = await rootBundle.loadString(asset);
    return jsonDecode(localData) as Map<String, dynamic>;
  }
}
