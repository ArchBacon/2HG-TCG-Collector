// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/routing/navigation.dart';
import 'package:app/themes/glass_theme.dart';
import 'package:app/tmp/core/utils/format.dart';
import 'package:app/ui/shared/glass/card_thumb.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A card in the catalog grid: the image with markers (owned count top-left, wishlisted top-right)
/// and its name over a dark fade at the bottom, then set code and price (when it has one), and the
/// number under them.
/// Opens the card.
class CatalogCardTile extends StatelessWidget {
  final TcgCard card;
  final Color accent; // For the wishlist marker

  const CatalogCardTile({super.key, required this.card, required this.accent});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return GestureDetector(
      onTap: () => context.openCard(card),
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CardThumb(
                  game: card.game,
                  imageUrl: card.imageUrl,
                  width: constraints.maxWidth,
                  radius: 8,
                  store: CardThumb.storeFor(card),
                ),
                // Dark fade at the bottom, so the name stays readable on any card
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xE6000000), Color(0x99000000), Color(0x00000000)],
                          stops: [0, 0.18, 0.4],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 6,
                  right: 6,
                  bottom: 6,
                  child: Text(
                    card.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: GlassTheme.onImage, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                if (card.owned > 0)
                  Positioned(
                    top: 5,
                    left: 5,
                    child: CatalogBadge(icon: LucideIcons.check, label: '${card.owned}', color: glass.positive),
                  ),
                if (card.wishlisted)
                  Positioned(
                    top: 5,
                    right: 5,
                    child: CatalogBadge(icon: LucideIcons.heart, color: accent),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  child: Text(
                    card.setCode.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: glass.textTertiary, fontSize: 11),
                  ),
                ),
                if (card.price > 0)
                  Text(
                    formatEuro(card.price),
                    style: TextStyle(color: glass.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
              ],
            ),
            Text(
              card.number,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: glass.textTertiary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small dark marker on the card image: an icon with an optional count.
class CatalogBadge extends StatelessWidget {
  final IconData icon;
  final String? label;
  final Color color;

  const CatalogBadge({super.key, required this.icon, this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xCC0A0D12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          if (label != null) ...[
            const SizedBox(width: 3),
            Text(
              label!,
              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }
}
