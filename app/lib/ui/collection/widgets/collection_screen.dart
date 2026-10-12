// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/ui/collection/widgets/collection_game_view.dart';
import 'package:app/ui/shared/app_state.dart';
import 'package:flutter/material.dart';

/// Collection tab: the collection of the selected game.
class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: selectedGame,
      builder: (context, game, _) => CollectionGameView(game: game),
    );
  }
}
