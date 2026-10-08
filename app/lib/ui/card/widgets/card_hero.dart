// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/themes/game_palette.dart';
import 'package:app/themes/glass_theme.dart';
import 'package:app/ui/shared/glass/card_thumb.dart';
import 'package:app/ui/shared/glass/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Top of the card page: the card large, with a soft glow in the game's color, then its name, set
/// and number, and rarity and game chips.
class CardHero extends StatelessWidget {
  final TcgCard card;

  const CardHero({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final glow = GamePalette.of(context, card.game).colors.first;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: glow.withValues(alpha: 0.45), blurRadius: 60, spreadRadius: 4),
              const BoxShadow(color: Color(0x80000000), blurRadius: 24, offset: Offset(0, 12)),
            ],
          ),
          child: CardThumb(game: card.game, width: MediaQuery.sizeOf(context).width * 0.58, radius: 14),
        ),
        const SizedBox(height: 24),
        Text(
          card.name,
          textAlign: TextAlign.center,
          style: TextStyle(color: glass.textPrimary, fontSize: 24, fontWeight: FontWeight.w700, height: 1.2),
        ),
        const SizedBox(height: 6),
        Text(
          '${card.setName} · ${card.number}',
          textAlign: TextAlign.center,
          style: TextStyle(color: glass.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            if (card.rarity != null) GlassChip(label: card.rarity!, icon: LucideIcons.gem),
            GlassChip(label: card.game.displayName),
          ],
        ),
      ],
    );
  }
}
