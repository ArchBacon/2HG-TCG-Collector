// Copyright 2026 Christian Delicaat. All rights reserved.

import '../tmp/shared/models/tcg.dart';

abstract final class Assets {
  static const collectionSummary = 'assets/data/collection_summary.json';
  static const wishlist = 'assets/data/wishlist.json';
  static const catalog = 'assets/data/catalog.json';
  static String collectionFor(Tcg tcg) => 'assets/data/collection/${tcg.slug}.json';
  static const images = _Images();
}

final class _Images {
  const _Images();

  String cardbackFor(Tcg tcg) => 'assets/tcgs/${tcg.slug}.webp';
}