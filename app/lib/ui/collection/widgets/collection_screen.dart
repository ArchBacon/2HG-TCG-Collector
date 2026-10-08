// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/ui/collection/widgets/collection_all_games_view.dart';
import 'package:app/ui/collection/widgets/collection_game_view.dart';
import 'package:app/ui/shared/app_state.dart';
import 'package:flutter/material.dart';

/// Collection tab: the collection of the selected game, or the totals per game with "All games"
/// picked.
class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: selectedGame,
      builder: (context, game, _) => game == null ? const CollectionAllGamesView() : CollectionGameView(game: game),
    );
  }
}
