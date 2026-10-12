// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/ui/card/widgets/card_screen_container.dart';
import 'package:app/ui/cart/widgets/cart_screen_container.dart';
import 'package:app/ui/catalog/widgets/catalog_screen_container.dart';
import 'package:app/ui/collection/widgets/collection_screen_container.dart';
import 'package:app/ui/settings/widgets/settings_screen.dart';
import 'package:app/ui/shared/app_state.dart';
import 'package:app/ui/shell/app_shell.dart';
import 'package:app/ui/start/widgets/start_screen_container.dart';
import 'package:app/ui/wishlist/widgets/wishlist_screen_container.dart';
import 'package:go_router/go_router.dart';

import 'routes.dart';

/// Top go_router entry point. Call after AppPreferences.load: where the app opens depends on the
/// saved settings.
GoRouter router() => GoRouter(
  // The start screen, or straight into the last game when that's switched on
  initialLocation: openLastGameOnStart.value ? Routes.gameHome : Routes.start,
  debugLogDiagnostics: true,
  routes: [
    GoRoute(path: Routes.start, builder: (context, state) => const StartScreenContainer()),
    // Bottom navigation tabs, for the selected game. Branch order must match the items in AppShell.
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: Routes.catalog, builder: (context, state) => const CatalogScreenContainer())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: Routes.collection, builder: (context, state) => const CollectionScreenContainer())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: Routes.wishlist, builder: (context, state) => const WishlistScreenContainer())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: Routes.settings, builder: (context, state) => const SettingsScreen())],
        ),
      ],
    ),
    // Outside the shell, so they cover the nav bar. The cart opens from the cart button in the
    // header; card details from any card; settings from the start screen.
    GoRoute(path: Routes.cart, builder: (context, state) => const CartScreenContainer()),
    GoRoute(path: Routes.card, builder: (context, state) => CardScreenContainer(cardId: state.pathParameters['id']!)),
    GoRoute(path: Routes.appSettings, builder: (context, state) => const SettingsScreen()),
  ],
);
