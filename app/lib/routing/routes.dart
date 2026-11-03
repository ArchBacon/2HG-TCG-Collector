// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/domain/models/collection/list_kind.dart';

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
  static const scan = '/scan'; // The camera, to scan a card

  /// The received notifications, under either settings page: '/settings/notifications' or
  /// '/app-settings/notifications'.
  static const notificationsPath = 'notifications';

  static String cardFor(String id) => '/card/$id';

  /// One of the user's collections or wishlists ([kind]), over its tab.
  static String listFor(ListKind kind, String id) => switch (kind) {
    ListKind.collection => '$collection/$id',
    ListKind.wishlist => '$wishlist/$id',
  };
}
