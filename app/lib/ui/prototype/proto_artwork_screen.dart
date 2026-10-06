// Copyright 2026 Christian Delicaat. All rights reserved.

// PROTOTYPE B: "Artwork". The game's own art, blown up and blurred, as the backdrop. Fewer boxes:
// the header and the new-in-store row sit directly on the backdrop; only the list is a glass card.

import 'package:app/ui/prototype/game_switcher.dart';
import 'package:app/ui/prototype/glass.dart';
import 'package:app/ui/prototype/proto_common.dart';
import 'package:app/ui/prototype/proto_data.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ProtoArtworkScreen extends StatelessWidget {
  const ProtoArtworkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProtoWishlistBuilder(
      builder: (context, game, cards) {
        final palette = GamePalette.of(game);
        final inStore = cards.where((c) => c.inStore).length;
        final newCards = cards.where((c) => c.isNew).toList();

        return ProtoScaffold(
          title: 'Wishlist',
          backdrop: ArtworkBackdrop(game: game),
          game: game,
          onGameChanged: (g) => protoGame.value = g,
          sidePadding: 0, // The new-in-store row runs edge to edge; the rest adds its own padding
          children: [
            // Header straight on the backdrop: title and chips, no card
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wishlist',
                    style: TextStyle(color: GlassText.primary, fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      GlassChip(icon: LucideIcons.heart, label: '${cards.length} cards'),
                      GlassChip(icon: LucideIcons.shoppingCart, label: '$inStore in store'),
                      if (newCards.isNotEmpty)
                        GlassChip(label: '${newCards.length} new', color: palette.accent, filled: true),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // New in store: bigger thumbnails, edge to edge, no container
            if (newCards.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: ProtoHeading('New in store'),
              ),
              SizedBox(
                height: 132 / CardThumb.aspect,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: newCards.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, i) => ProtoOverlayThumb(card: newCards[i], width: 132),
                ),
              ),
              const SizedBox(height: 28),
            ],

            // Everything, as rows in one glass card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ProtoHeading('All wishlisted'),
                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (final (i, card) in cards.indexed) ...[
                          if (i > 0) Divider(height: 1, thickness: 1, color: GlassColors.current.divider, indent: 72),
                          _Row(card: card, accent: palette.accent),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// Thumbnail, name, set and number, and store status on the right.
class _Row extends StatelessWidget {
  final ProtoCard card;
  final Color accent;

  const _Row({required this.card, required this.accent});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => openCard(context, card),
      child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(
        children: [
          CardThumb(game: card.game, width: 44, radius: 5),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.quantity > 1 ? '${card.name}  ×${card.quantity}' : card.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: GlassText.primary, fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${card.setName} · ${card.number}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: GlassText.tertiary, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (card.isNew)
            GlassChip(label: 'New', color: accent, filled: true)
          else if (card.inStore)
            const GlassChip(icon: LucideIcons.shoppingCart, label: 'In store')
          else
            Text('Not in store', style: TextStyle(color: GlassText.tertiary, fontSize: 12)),
        ],
      ),
      ),
    );
  }
}
