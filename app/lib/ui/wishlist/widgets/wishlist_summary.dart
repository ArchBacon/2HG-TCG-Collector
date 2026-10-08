// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/ui/shared/glass/layout.dart';
import 'package:flutter/material.dart';

/// Wishlist totals: wanted copies, how many cards are in the store, and how many of those are new.
class WishlistSummary extends StatelessWidget {
  final List<TcgCard> cards;
  final Color accent; // For the "new" count
  final String? caption;

  const WishlistSummary({super.key, required this.cards, required this.accent, this.caption});

  @override
  Widget build(BuildContext context) {
    return StatsCard(
      caption: caption,
      stats: [
        StatValue(value: '${cards.fold(0, (n, c) => n + c.quantity)}', label: 'Wishlisted'),
        StatValue(value: '${cards.where((c) => c.inStore).length}', label: 'In store'),
        StatValue(value: '${cards.where((c) => c.isNew).length}', label: 'New', color: accent),
      ],
    );
  }
}
