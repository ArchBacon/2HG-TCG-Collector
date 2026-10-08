// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/routing/navigation.dart';
import 'package:app/themes/glass_theme.dart';
import 'package:app/ui/shared/glass/card_thumb.dart';
import 'package:app/ui/shared/glass/glass_card.dart';
import 'package:app/ui/shared/glass/layout.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// One set of the wishlist: the set's name and card count, then a grid of its wishlisted cards
/// with their store status.
class WishlistSetCard extends StatelessWidget {
  final String setName;
  final List<TcgCard> cards;
  final Color accent;

  const WishlistSetCard({super.key, required this.setName, required this.cards, required this.accent});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

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
                  style: TextStyle(color: glass.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '${cards.length} ${cards.length == 1 ? 'card' : 'cards'}',
                style: TextStyle(color: glass.textTertiary, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ColumnGrid(
            columns: 4,
            gap: 10,
            children: [for (final card in cards) _WishlistCard(card: card, accent: accent)],
          ),
        ],
      ),
    );
  }
}

/// Card image with small markers (wanted quantity top-left, store status bottom-right) and its
/// name underneath. Cards that aren't in the store are dimmed, so what you can buy stands out.
class _WishlistCard extends StatelessWidget {
  final TcgCard card;
  final Color accent;

  const _WishlistCard({required this.card, required this.accent});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.openCard(card),
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Opacity(opacity: card.inStore ? 1 : 0.45, child: CardThumb(game: card.game, width: constraints.maxWidth)),
                if (card.quantity > 1)
                  Positioned(top: 4, left: 4, child: _Marker(label: '×${card.quantity}', color: GlassTheme.onImage)),
                if (card.inStore)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: card.isNew
                        ? _Marker(label: 'NEW', color: accent)
                        : const _Marker(icon: LucideIcons.shoppingCart, color: GlassTheme.onImage),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              card.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.glass.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small dark label on a card image: a text ("×2", "NEW") or an icon.
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
