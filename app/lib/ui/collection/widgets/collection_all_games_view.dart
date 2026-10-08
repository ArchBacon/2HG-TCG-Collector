// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/services/mock/mock_data.dart';
import 'package:app/domain/models/collection/collection_stats.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/ui/collection/widgets/collection_value_card.dart';
import 'package:app/ui/shared/glass/game_tile.dart';
import 'package:app/ui/shared/glass/glass_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The collection with "All games" picked: the total value, and a tile per game (tapping one picks
/// that game).
class CollectionAllGamesView extends StatelessWidget {
  const CollectionAllGamesView({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: MockData.allCollections(),
      builder: (context, snapshot) {
        final collections = snapshot.data ?? const <Tcg, CollectionStats>{};
        final games = collections.entries.toList()..sort((a, b) => b.value.value.compareTo(a.value.value)); // Most valuable first

        return GlassScaffold(
          title: 'Collection',
          game: null,
          showGameSwitcher: false, // The game tiles below are the game picker on this page
          children: [
            TotalValueCard(
              value: collections.values.fold(0.0, (sum, c) => sum + c.value),
              cards: collections.values.fold(0, (n, c) => n + c.collected),
              games: collections.length,
            ),
            const SizedBox(height: 14),
            GameTileGrid(
              tiles: [
                for (final MapEntry(key: game, value: collection) in games)
                  GameTile(
                    game: game,
                    stats: [
                      (LucideIcons.layers, '${collection.collected}'),
                      (LucideIcons.euro, collection.value.toStringAsFixed(0)),
                    ],
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
