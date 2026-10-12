// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/services/mock/mock_data.dart';
import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/domain/models/collection/collection_stats.dart';
import 'package:app/routing/routes.dart';
import 'package:app/themes/glass_theme.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/ui/shared/glass/glass_scaffold.dart';
import 'package:app/ui/shared/glass/layout.dart';
import 'package:app/ui/start/widgets/game_picker_grid.dart';
import 'package:app/ui/start/widgets/totals_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The start screen, shown on every launch (unless "Open last game on start" is on) and from the
/// brand icon: totals across all games, and a tile per game to open it. No nav bar; settings and
/// the cart are in the header.
class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: (MockData.allCollections(), MockData.wishlist()).wait,
      builder: (context, snapshot) {
        final (collections, wishlist) = snapshot.data ?? (const <Tcg, CollectionStats>{}, const <TcgCard>[]);

        return GlassScaffold(
          title: 'TCG Collector',
          game: null,
          showGameSwitcher: false,
          isStartScreen: true,
          actions: const [_SettingsButton()],
          children: [
            TotalsCard(
              collected: collections.values.fold(0, (n, c) => n + c.collected),
              wishlisted: collections.values.fold(0, (n, c) => n + c.wishlisted),
            ),
            const SizedBox(height: 24),
            const SectionHeading('Select a game'), // Not "your games": every game is listed, also ones without cards
            GamePickerGrid(collections: collections, wishlist: wishlist),
          ],
        );
      },
    );
  }
}

/// Opens the settings as a page of its own (the start screen has no nav bar).
class _SettingsButton extends StatelessWidget {
  const _SettingsButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Settings',
      onPressed: () => context.push(Routes.appSettings),
      icon: Icon(LucideIcons.settings, size: 22, color: context.glass.textPrimary),
    );
  }
}
