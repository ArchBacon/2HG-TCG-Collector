// Copyright 2026 Christian Delicaat. All rights reserved.

abstract final class Routes {
  /// Picks the game; shown on every launch (unless "open last game on start" is on), without the
  /// nav bar.
  static const start = '/';

  // Tabs, for the selected game
  static const catalog = '/catalog';
  static const collection = '/collection';
  static const wishlist = '/wishlist';
  static const settings = '/settings';

  /// The tab a game opens on, from the start screen.
  static const gameHome = catalog;

  // Full-screen pages over the tabs
  static const cart = '/cart';
  static const card = '/card/:id';
  static const appSettings = '/app-settings'; // The settings, opened from the start screen

  static String cardFor(String id) => '/card/$id';
}
