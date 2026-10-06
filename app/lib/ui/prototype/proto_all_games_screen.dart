// Copyright 2026 Christian Delicaat. All rights reserved.

// PROTOTYPE C: the wishlist with "All games" picked in the switcher. Instead of full-width game
// bars (too close to the home screen), a 2-column grid of compact game tiles, each tinted in its
// game's colors. Tapping one picks that game, which turns the tab into that game's wishlist.

import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/ui/prototype/game_switcher.dart';
import 'package:app/ui/prototype/glass.dart';
import 'package:app/ui/prototype/proto_common.dart';
import 'package:app/ui/prototype/proto_data.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ProtoAllGamesScreen extends StatelessWidget {
  const ProtoAllGamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: ProtoData.wishlist(),
      builder: (context, snapshot) {
        final cards = snapshot.data ?? const <ProtoCard>[];
        final palette = GamePalette.of(null);
        final newCards = cards.where((c) => c.isNew).toList();
        final games = [for (final game in Tcg.values) (game, cards.where((c) => c.game == game).toList())]
          ..sort((a, b) => b.$2.length.compareTo(a.$2.length)); // Most wishlisted first

        return ProtoScaffold(
          title: 'Wishlist',
          game: null,
          children: [
            // Summary across all games
            GlassCard(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wishlist across all games',
                    style: TextStyle(color: GlassText.secondary, fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: ProtoStat(value: '${cards.length}', label: 'Wishlisted')),
                      Expanded(child: ProtoStat(value: '${cards.where((c) => c.inStore).length}', label: 'In store')),
                      Expanded(child: ProtoStat(value: '${newCards.length}', label: 'New', color: palette.accent)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // New in store, across all games
            if (newCards.isNotEmpty) ...[
              GlassCard(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(LucideIcons.sparkles, size: 16, color: palette.accent),
                          const SizedBox(width: 8),
                          Text(
                            'New in store',
                            style: TextStyle(color: GlassText.primary, fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 104 / CardThumb.aspect,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: newCards.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, i) => ProtoOverlayThumb(card: newCards[i], width: 104),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Game tiles, two per row
            ProtoGrid(
              columns: 2,
              children: [
                for (final (game, gameCards) in games)
                  ProtoGameTile(
                    game: game,
                    stats: [
                      (LucideIcons.heart, '${gameCards.length}'),
                      (LucideIcons.shoppingCart, '${gameCards.where((c) => c.inStore).length}'),
                    ],
                    newCount: gameCards.where((c) => c.isNew).length,
                    onTap: () => protoGame.value = game,
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
