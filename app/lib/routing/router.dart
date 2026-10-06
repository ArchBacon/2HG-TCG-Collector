// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/ui/overview/widgets/overview_screen_container.dart';
import 'package:app/ui/prototype/proto_artwork_screen.dart';
import 'package:app/ui/prototype/proto_card_screen.dart';
import 'package:app/ui/prototype/proto_cart_screen.dart';
import 'package:app/ui/prototype/proto_catalog_screen.dart';
import 'package:app/ui/prototype/proto_collection_screen.dart';
import 'package:app/ui/prototype/proto_mesh_screen.dart';
import 'package:app/ui/prototype/proto_settings_screen.dart';
import 'package:app/ui/prototype/proto_wishlist_tab.dart';
import 'package:app/ui/shell/app_shell.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../tmp/shared/models/tcg.dart';
import 'routes.dart';

/// Top go_router entry point.
///
/// PROTOTYPE: every tab shows a design prototype from lib/ui/prototype/. The real screens were:
/// Collection = HomeScreenContainer, Wishlist = WishlistScreenContainer, Catalog/Cart/Settings =
/// PlaceholderScreen. The cart moved from the nav bar to a button in the header.
GoRouter router() => GoRouter(
  initialLocation: Routes.wishlist,
  debugLogDiagnostics: true,
  routes: [
    // Bottom navigation tabs. Branch order must match the items in AppShell.
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
      branches: [
        // Collection
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.home,
              builder: (context, state) => const ProtoCollectionScreen(),
            ),
            GoRoute(
              path: Routes.overview,
              builder: (context, state) {
                final slug = state.pathParameters['tcg']!;
                final tcg = Tcg.values.firstWhere((t) => t.slug == slug);
                return OverviewScreenContainer(key: ValueKey(tcg), tcg: tcg);
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.wishlist,
              builder: (context, state) => const ProtoWishlistTab(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.catalog,
              builder: (context, state) => const ProtoCatalogScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.settings,
              builder: (context, state) => const ProtoSettingsScreen(),
              routes: [
                // Wishlist layouts A and B, opened from the settings
                GoRoute(
                  path: 'mesh',
                  builder: (context, state) => const ProtoMeshScreen(),
                ),
                GoRoute(
                  path: 'artwork',
                  builder: (context, state) => const ProtoArtworkScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    // Cart and card details: outside the shell, so they cover the nav bar. The cart is opened from
    // the cart button in the header.
    GoRoute(
      path: Routes.cart,
      builder: (context, state) => const ProtoCartScreen(),
    ),
    GoRoute(
      path: Routes.card,
      builder: (context, state) => ProtoCardScreen(cardId: state.pathParameters['id']!),
    ),
  ],
);
