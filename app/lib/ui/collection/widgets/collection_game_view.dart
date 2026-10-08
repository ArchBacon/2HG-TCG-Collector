// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/services/mock/mock_data.dart';
import 'package:app/domain/models/collection/collection_stats.dart';
import 'package:app/themes/game_palette.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/ui/collection/widgets/collection_value_card.dart';
import 'package:app/ui/collection/widgets/recently_added_row.dart';
import 'package:app/ui/collection/widgets/set_progress_list.dart';
import 'package:app/ui/shared/glass/glass_scaffold.dart';
import 'package:flutter/material.dart';

/// The collection of one game: its value and progress, the cards added last, and progress per set.
class CollectionGameView extends StatelessWidget {
  final Tcg game;

  const CollectionGameView({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final accent = GamePalette.of(context, game).accent;
    final recent = MockData.catalog(game).where((c) => c.owned > 0).take(10).toList();

    return FutureBuilder(
      future: MockData.collection(game),
      builder: (context, snapshot) {
        final collection = snapshot.data;
        final sets = collection?.sets ?? const <SetProgress>[];

        return GlassScaffold(
          title: 'Collection',
          game: game,
          children: [
            CollectionValueCard(collection: collection, accent: accent),
            const SizedBox(height: 24),
            RecentlyAddedRow(cards: recent),
            const SizedBox(height: 24),
            SetProgressList(sets: sets, accent: accent),
          ],
        );
      },
    );
  }
}
