// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/themes/glass_theme.dart';
import 'package:app/ui/shared/glass/card_thumb.dart';
import 'package:app/ui/shared/glass/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Wishlisted cards that were recently added to the store, as a sideways-scrolling row.
class NewInStoreCard extends StatelessWidget {
  final List<TcgCard> cards;
  final Color accent;

  const NewInStoreCard({super.key, required this.cards, required this.accent});

  static const _thumbWidth = 104.0;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(LucideIcons.sparkles, size: 16, color: accent),
                const SizedBox(width: 8),
                Text(
                  'New in store',
                  style: TextStyle(color: context.glass.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: _thumbWidth / CardThumb.aspect,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: cards.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) => CardOverlayThumb(card: cards[i], width: _thumbWidth),
            ),
          ),
        ],
      ),
    );
  }
}
