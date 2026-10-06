// Copyright 2026 Christian Delicaat. All rights reserved.

// PROTOTYPE A: "Mesh". Soft color fields in the game's palette, everything in glass cards.
// Summary card -> new-in-store card -> the wishlist itself as card grids, one glass card per set.

import 'package:app/ui/prototype/glass.dart';
import 'package:app/ui/prototype/proto_common.dart';
import 'package:app/ui/prototype/proto_data.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ProtoMeshScreen extends StatelessWidget {
  const ProtoMeshScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProtoWishlistBuilder(
      builder: (context, game, cards) {
        final palette = GamePalette.of(game);
        final inStore = cards.where((c) => c.inStore).length;
        final newCards = cards.where((c) => c.isNew).toList();

        return ProtoScaffold(
          title: 'Wishlist',
          game: game,
          children: [
            // Summary
            GlassCard(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Row(
                children: [
                  Expanded(child: ProtoStat(value: '${cards.fold(0, (n, c) => n + c.quantity)}', label: 'Wishlisted')),
                  Expanded(child: ProtoStat(value: '$inStore', label: 'In store')),
                  Expanded(child: ProtoStat(value: '${newCards.length}', label: 'New', color: palette.accent)),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // New in store
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

            // The wishlist, one glass card per set
            for (final MapEntry(key: setName, value: setCards) in groupBySet(cards).entries) ...[
              _SetCard(setName: setName, cards: setCards, accent: palette.accent),
              const SizedBox(height: 14),
            ],
          ],
        );
      },
    );
  }
}

// One set: name and count, then a grid of the wishlisted cards with their store status.
class _SetCard extends StatelessWidget {
  final String setName;
  final List<ProtoCard> cards;
  final Color accent;

  const _SetCard({required this.setName, required this.cards, required this.accent});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  setName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: GlassText.primary, fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '${cards.length} ${cards.length == 1 ? 'card' : 'cards'}',
                style: TextStyle(color: GlassText.tertiary, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              const columns = 4;
              const gap = 10.0;
              final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: 12,
                children: [for (final card in cards) _GridCard(card: card, width: width, accent: accent)],
              );
            },
          ),
        ],
      ),
    );
  }
}

// Card image with small markers: quantity top-left, store status bottom-right; name underneath.
class _GridCard extends StatelessWidget {
  final ProtoCard card;
  final double width;
  final Color accent;

  const _GridCard({required this.card, required this.width, required this.accent});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openCard(context, card),
      child: SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              // Not in store: dimmed, so what you can buy stands out
              Opacity(opacity: card.inStore ? 1 : 0.45, child: CardThumb(game: card.game, width: width)),
              if (card.quantity > 1)
                Positioned(top: 4, left: 4, child: _Marker(label: '×${card.quantity}', color: GlassText.onImage)),
              if (card.inStore)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: card.isNew
                      ? _Marker(label: 'NEW', color: accent)
                      : const _Marker(icon: LucideIcons.shoppingCart, color: GlassText.onImage),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            card.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: GlassText.secondary, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
      ),
    );
  }
}

class _Marker extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final Color color;

  const _Marker({this.label, this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: label == null ? 4 : 5, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xCC0A0D12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: label != null
          ? Text(label!, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.3))
          : Icon(icon, size: 10, color: color),
    );
  }
}
