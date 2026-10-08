// Copyright 2026 Christian Delicaat. All rights reserved.

import 'dart:math';

import 'package:app/domain/models/card/market_info.dart';
import 'package:app/themes/glass_theme.dart';
import 'package:app/tmp/core/utils/format.dart';
import 'package:app/ui/shared/glass/glass_card.dart';
import 'package:app/ui/shared/glass/layout.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// "For sale": the store listings for the card (condition, seller, stock, price, add button), or a
/// note that it's not in store.
class ListingsSection extends StatelessWidget {
  final List<StoreListing> listings;
  final ValueChanged<StoreListing> onAdd;

  const ListingsSection({super.key, required this.listings, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeading(
          'For sale',
          trailing: listings.isEmpty
              ? null
              : Text(
                  '${listings.length} listings · from ${formatEuro(listings.map((l) => l.price).reduce(min))}',
                  style: TextStyle(color: glass.textTertiary, fontSize: 13),
                ),
        ),
        if (listings.isEmpty)
          GlassCard(
            child: Row(
              children: [
                Icon(LucideIcons.bellRing, size: 18, color: glass.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Not in store right now. Wishlist it to get notified when it is.',
                    style: TextStyle(color: glass.textSecondary, fontSize: 14),
                  ),
                ),
              ],
            ),
          )
        else
          GlassListCard(rows: [for (final listing in listings) _ListingRow(listing: listing, onAdd: () => onAdd(listing))]),
      ],
    );
  }
}

class _ListingRow extends StatelessWidget {
  final StoreListing listing;
  final VoidCallback onAdd;

  const _ListingRow({required this.listing, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(listing.condition, style: TextStyle(color: glass.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('${listing.seller} · ${listing.stock} available', style: TextStyle(color: glass.textTertiary, fontSize: 12)),
              ],
            ),
          ),
          Text(formatEuro(listing.price), style: TextStyle(color: glass.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'Add to cart',
            onPressed: onAdd,
            icon: const Icon(LucideIcons.plus, size: 18),
            color: glass.textPrimary,
            style: IconButton.styleFrom(backgroundColor: glass.fill),
          ),
        ],
      ),
    );
  }
}
