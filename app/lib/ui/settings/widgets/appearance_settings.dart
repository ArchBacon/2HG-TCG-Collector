// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/themes/glass_theme.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/ui/settings/widgets/setting_row.dart';
import 'package:app/ui/shared/app_state.dart';
import 'package:app/ui/shared/glass/game_switcher.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Theme (system / light / dark) and the game the screens show.
class AppearanceSettings extends StatelessWidget {
  final Tcg? game;
  final Color accent;

  const AppearanceSettings({super.key, required this.game, required this.accent});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return SettingsGroup(
      title: 'Appearance',
      rows: [
        SettingRow(
          icon: LucideIcons.sunMoon,
          title: 'Theme',
          trailing: ValueListenableBuilder(
            valueListenable: themeModeSetting,
            builder: (context, mode, _) => SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                foregroundColor: glass.textSecondary,
                selectedForegroundColor: accent,
                selectedBackgroundColor: accent.withValues(alpha: 0.18),
                side: BorderSide(color: glass.edge),
                visualDensity: VisualDensity.compact,
              ),
              segments: const [
                ButtonSegment(value: ThemeMode.system, icon: Icon(LucideIcons.smartphone, size: 16), tooltip: 'System'),
                ButtonSegment(value: ThemeMode.light, icon: Icon(LucideIcons.sun, size: 16), tooltip: 'Light'),
                ButtonSegment(value: ThemeMode.dark, icon: Icon(LucideIcons.moon, size: 16), tooltip: 'Dark'),
              ],
              selected: {mode},
              onSelectionChanged: (selection) => themeModeSetting.value = selection.first,
            ),
          ),
        ),
        SettingRow(
          icon: LucideIcons.layoutGrid,
          title: 'Game',
          value: game?.displayName ?? 'All games',
          onTap: () async {
            final picked = await showGameSheet(context, current: game);
            if (picked != null) selectedGame.value = picked.game;
          },
        ),
      ],
    );
  }
}
