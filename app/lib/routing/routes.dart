// Copyright 2026 Christian Delicaat. All rights reserved.

abstract final class Routes {
  // Tabs
  static const collection = '/';
  static const wishlist = '/wishlist';
  static const catalog = '/catalog';
  static const settings = '/settings';

  // Full-screen pages over the tabs
  static const cart = '/cart';
  static const card = '/card/:id';

  static String cardFor(String id) => '/card/$id';
}
