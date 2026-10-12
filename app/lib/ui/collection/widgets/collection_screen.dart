// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/themes/game_palette.dart';
import 'package:app/ui/collection/view_models/collection_viewmodel.dart';
import 'package:app/ui/collection/widgets/collection_value_card.dart';
import 'package:app/ui/collection/widgets/recently_added_row.dart';
import 'package:app/ui/collection/widgets/set_progress_list.dart';
import 'package:app/ui/shared/glass/glass_scaffold.dart';
import 'package:flutter/material.dart';

/// Collection tab: one game's collection. Its value and progress, the cards added last, and
/// progress per set.
class CollectionScreen extends StatelessWidget {
  final CollectionViewModel viewModel;

  const CollectionScreen({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final accent = GamePalette.of(context, viewModel.tcg).accent;

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) => GlassScaffold(
        title: 'Collection',
        game: viewModel.tcg,
        children: [
          CollectionValueCard(collection: viewModel.overview, sets: viewModel.sets, accent: accent),
          const SizedBox(height: 24),
          RecentlyAddedRow(cards: viewModel.recentlyAdded),
          const SizedBox(height: 24),
          SetProgressList(sets: viewModel.sets, accent: accent),
        ],
      ),
    );
  }
}
