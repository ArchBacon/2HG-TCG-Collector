// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/routing/routes.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/ui/shared/app_state.dart';
import 'package:app/ui/shared/glass/game_tile.dart';
import 'package:app/ui/start/view_models/start_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A tile per game, each with its card count, value and wishlist cards new in store. Tapping one
/// opens that game. Always in the same order (not sorted by collection), so tiles don't move around
/// as the collection changes.
class GamePickerGrid extends StatelessWidget {
  final StartViewModel viewModel;

  const GamePickerGrid({super.key, required this.viewModel});

  void _open(BuildContext context, Tcg game) {
    selectedGame.value = game;
    cardSearch.value = ''; // A search was for the previous game
    context.go(Routes.gameHome);
  }

  @override
  Widget build(BuildContext context) {
    return GameTileGrid(
      tiles: [
        for (final game in Tcg.values)
          GameTile(
            game: game,
            stats: [
              (LucideIcons.layers, '${viewModel.collectionFor(game)?.collected ?? 0}'),
              (LucideIcons.euro, (viewModel.collectionFor(game)?.value ?? 0).toStringAsFixed(0)),
            ],
            newCount: viewModel.newInStoreFor(game),
            onTap: () => _open(context, game),
          ),
      ],
    );
  }
}
