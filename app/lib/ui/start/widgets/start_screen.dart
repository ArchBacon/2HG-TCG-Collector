// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/routing/routes.dart';
import 'package:app/themes/glass_theme.dart';
import 'package:app/ui/shared/glass/glass_scaffold.dart';
import 'package:app/ui/shared/glass/layout.dart';
import 'package:app/ui/start/view_models/start_viewmodel.dart';
import 'package:app/ui/start/widgets/game_picker_grid.dart';
import 'package:app/ui/start/widgets/totals_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The start screen, shown on every launch (unless "Open last game on start" is on) and from the
/// brand icon: totals across all games, and a tile per game to open it. No nav bar; settings and
/// the cart are in the header.
class StartScreen extends StatelessWidget {
  final StartViewModel viewModel;

  const StartScreen({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) => GlassScaffold(
        title: 'TCG Collector',
        game: null,
        showGameSwitcher: false,
        isStartScreen: true,
        actions: const [_SettingsButton()],
        children: [
          TotalsCard(collected: viewModel.collected, wishlisted: viewModel.wishlisted),
          const SizedBox(height: 24),
          const SectionHeading('Select a game'), // Not "your games": every game is listed, also ones without cards
          GamePickerGrid(viewModel: viewModel),
        ],
      ),
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
