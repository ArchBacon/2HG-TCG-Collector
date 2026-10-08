// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/services/mock/mock_data.dart';
import 'package:app/themes/glass_theme.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/ui/shared/glass/game_tile.dart';
import 'package:app/ui/shared/glass/glass_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The catalog with "All games" picked: the catalog is per game, so pick one first.
class CatalogGamePicker extends StatelessWidget {
  const CatalogGamePicker({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      title: 'Catalog',
      game: null,
      showGameSwitcher: false, // The game tiles below are the game picker on this page
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 16),
          child: Text(
            'Which catalog do you want to browse?',
            style: TextStyle(color: context.glass.textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ),
        GameTileGrid(
          tiles: [
            for (final game in Tcg.values)
              GameTile(game: game, stats: [(LucideIcons.library, '${MockData.catalog(game).length} cards')]),
          ],
        ),
      ],
    );
  }
}
