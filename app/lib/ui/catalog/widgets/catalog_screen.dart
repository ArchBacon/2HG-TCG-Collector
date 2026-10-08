// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/ui/catalog/widgets/catalog_game_picker.dart';
import 'package:app/ui/catalog/widgets/catalog_view.dart';
import 'package:app/ui/shared/app_state.dart';
import 'package:flutter/material.dart';

/// Catalog tab: every card of the selected game. The catalog is per game, so with "All games"
/// picked it asks which game first.
class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: selectedGame,
      // Keyed by game, so the filters reset when the game changes
      builder: (context, game, _) =>
          game == null ? const CatalogGamePicker() : CatalogView(key: ValueKey(game), game: game),
    );
  }
}
