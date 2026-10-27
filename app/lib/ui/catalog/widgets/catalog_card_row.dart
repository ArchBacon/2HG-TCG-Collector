// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/routing/navigation.dart';
import 'package:app/themes/glass_theme.dart';
import 'package:app/tmp/core/utils/format.dart';
import 'package:app/ui/catalog/widgets/catalog_card_tile.dart';
import 'package:app/ui/shared/glass/card_thumb.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A card in the catalog list: a small image, then name, set code and number, and rarity, with the
/// price (when it has one) and markers (owned count, wishlisted) on the right. Opens the card.
class CatalogCardRow extends StatelessWidget {
  final TcgCard card;
  final Color accent; // For the wishlist marker

  const CatalogCardRow({super.key, required this.card, required this.accent});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.openCard(card),
        child: Ink(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: glass.fill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: glass.edge),
          ),
          child: Row(
            children: [
              CardThumb(game: card.game, imageUrl: card.imageUrl, width: 44, radius: 4, store: CardThumb.storeFor(card)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: glass.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${card.setCode.toUpperCase()} · ${card.number}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: glass.textSecondary, fontSize: 12),
                    ),
                    if (card.rarity != null)
                      Text(
                        card.rarity!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: glass.textTertiary, fontSize: 11),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (card.price > 0)
                    Text(
                      formatEuro(card.price),
                      style: TextStyle(color: glass.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  if (card.owned > 0 || card.wishlisted) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (card.owned > 0)
                          CatalogBadge(icon: LucideIcons.check, label: '${card.owned}', color: glass.positive),
                        if (card.owned > 0 && card.wishlisted) const SizedBox(width: 4),
                        if (card.wishlisted) CatalogBadge(icon: LucideIcons.heart, color: accent),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
