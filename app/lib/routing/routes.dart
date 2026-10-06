// Copyright 2026 Christian Delicaat. All rights reserved.

import '../tmp/shared/models/tcg.dart';

abstract final class Routes {
  static const home = '/';
  static const overview = '/overview/:tcg';
  static const wishlist = '/wishlist';
  static const catalog = '/catalog';
  static const cart = '/cart';
  static const settings = '/settings';

  // PROTOTYPE
  static const card = '/card/:id';
  static const protoMesh = '/settings/mesh';
  static const protoArtwork = '/settings/artwork';

  static String overviewFor(Tcg tcg) => '/overview/${tcg.slug}';
  static String cardFor(String id) => '/card/$id';
}
