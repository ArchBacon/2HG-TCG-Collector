// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/themes/game_palette.dart';
import 'package:app/ui/settings/widgets/account_card.dart';
import 'package:app/ui/settings/widgets/appearance_settings.dart';
import 'package:app/ui/settings/widgets/notification_settings.dart';
import 'package:app/ui/settings/widgets/other_settings.dart';
import 'package:app/ui/shared/app_state.dart';
import 'package:app/ui/shared/glass/glass_scaffold.dart';
import 'package:flutter/material.dart';

/// Settings tab: grouped glass lists. Theme, game and the notification switches work; the rest are
/// placeholders. Follows the selected game for its background and accent.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: selectedGame,
      builder: (context, game, _) {
        final accent = GamePalette.of(context, game).accent;

        return GlassScaffold(
          game: game,
          title: 'Settings',
          showGameSwitcher: false,
          children: [
            AccountCard(accent: accent),
            AppearanceSettings(game: game, accent: accent),
            NotificationSettings(accent: accent),
            const StoreSettings(),
            const CollectionDataSettings(),
            const AboutSettings(),
          ],
        );
      },
    );
  }
}
