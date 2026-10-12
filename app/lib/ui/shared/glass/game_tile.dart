// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/themes/game_palette.dart';
import 'package:app/themes/glass_theme.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/ui/shared/glass/card_thumb.dart';
import 'package:app/ui/shared/glass/glass_card.dart';
import 'package:app/ui/shared/glass/layout.dart';
import 'package:flutter/material.dart';

/// Compact game tile, for picking a game: the game's color glowing in the corner, its cardback
/// peeking in, the name and two small stats.
class GameTile extends StatelessWidget {
  final Tcg game;
  final List<(IconData icon, String label)> stats;
  final int newCount; // Shows a "N new" chip when above 0
  final VoidCallback onTap;

  const GameTile({super.key, required this.game, required this.stats, this.newCount = 0, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final palette = GamePalette.of(context, game);
    final tint = palette.colors.first;

    return GlassCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: SizedBox(
        height: 150,
        child: Stack(
          children: [
            // The game's color glowing from the top-right
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(1, -1),
                    radius: 1.2,
                    colors: [tint.withValues(alpha: 0.35), tint.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
            // Cardback peeking in from the top-right, tilted
            Positioned(
              top: -14,
              right: -12,
              child: Transform.rotate(
                angle: 0.25,
                child: Opacity(opacity: 0.9, child: CardThumb(game: game, width: 58, radius: 6)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (newCount > 0) GlassChip(label: '$newCount new', color: palette.accent, filled: true),
                  const Spacer(),
                  Text(
                    game.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: glass.textPrimary, fontSize: 15, fontWeight: FontWeight.w700, height: 1.2),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      for (final (i, (icon, label)) in stats.indexed) ...[
                        if (i > 0) const SizedBox(width: 12),
                        Icon(icon, size: 12, color: glass.textTertiary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: glass.textSecondary, fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The game tiles, two per row.
class GameTileGrid extends StatelessWidget {
  final List<GameTile> tiles;

  const GameTileGrid({super.key, required this.tiles});

  @override
  Widget build(BuildContext context) => ColumnGrid(columns: 2, children: tiles);
}
