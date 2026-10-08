// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/ui/card/widgets/card_screen.dart';
import 'package:app/ui/cart/widgets/cart_screen.dart';
import 'package:app/ui/catalog/widgets/catalog_screen.dart';
import 'package:app/ui/collection/widgets/collection_screen.dart';
import 'package:app/ui/settings/widgets/settings_screen.dart';
import 'package:app/ui/shell/app_shell.dart';
import 'package:app/ui/wishlist/widgets/wishlist_screen.dart';
import 'package:go_router/go_router.dart';

import 'routes.dart';

/// Top go_router entry point.
GoRouter router() => GoRouter(
  initialLocation: Routes.wishlist,
  debugLogDiagnostics: true,
  routes: [
    // Bottom navigation tabs. Branch order must match the items in AppShell.
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: Routes.collection, builder: (context, state) => const CollectionScreen())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: Routes.wishlist, builder: (context, state) => const WishlistScreen())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: Routes.catalog, builder: (context, state) => const CatalogScreen())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: Routes.settings, builder: (context, state) => const SettingsScreen())],
        ),
      ],
    ),
    // Outside the shell, so they cover the nav bar. The cart opens from the cart button in the
    // header; card details from any card.
    GoRoute(path: Routes.cart, builder: (context, state) => const CartScreen()),
    GoRoute(path: Routes.card, builder: (context, state) => CardScreen(cardId: state.pathParameters['id']!)),
  ],
);
