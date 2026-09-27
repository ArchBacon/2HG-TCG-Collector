// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../tmp/core/utils/format.dart';
import '../tmp/shared/theme/app_colors.dart';

// The card gradient isn't in the Stitch values; it's measured from references/collection_value.png.
const _cardTop = Color(0xFF141923); // Background color at the top of the card
const _cardBottom = Color(0xFF171C24); // Background color at the bottom of the card
const _cardGlow = Color(0x1A5CB85C); // brand green (0xFF5CB85C) at 10%

// The total collection value card at the top of the home screen.
class CollectionSummaryCard extends StatelessWidget {
  final double value; // Total value in euros
  final int collected; // Shown in the "Cataloged" tile
  final int wishlisted; // Shown in the "Wishlisted" tile

  const CollectionSummaryCard({
    super.key,
    required this.value,
    required this.collected,
    required this.wishlisted,
  });

  @override
  Widget build(BuildContext context) {
    // Two layers: a dark base that lightens slightly downwards, and a faint brand-green glow from the right.
    // Outer layer: base gradient, border, rounded corners and shadow
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_cardTop, _cardBottom],
        ),
        border: Border.all(color: AppColors.cardBorder), // 1px border
        borderRadius: BorderRadius.circular(16), // Corner radius
        boxShadow: const [
          BoxShadow(color: Color(0x59000000), blurRadius: 16, offset: Offset(0, 4)), // Black 35%, soft, 4px down
        ],
      ),
      // Inner layer: the green glow, and the padding around the content
      child: Container(
        padding: const EdgeInsets.all(11), // + 1px border = 12
        decoration: BoxDecoration(
          // 15 = the card's 16px radius minus the 1px border it sits inside
          borderRadius: BorderRadius.circular(15),
          gradient: const RadialGradient(
            center: Alignment(0.9, 0.5), // Glow center: x -1..1 (left..right), y -1..1 (top..bottom)
            radius: 1.5, // Glow size; larger = spreads further left
            colors: [_cardGlow, Color(0x005CB85C)], // From the glow color to fully transparent
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label above the value
            const Text(
              'Collection value',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6), // Gap between label and value
            // Total value
            Text(
              formatEuro(value),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 36,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
                height: 1.1, // Line height; keeps the big number from taking extra vertical space
                fontFeatures: [FontFeature.tabularFigures()], // Equal-width digits
              ),
            ),
            const SizedBox(height: 20), // Gap between value and the tiles
            // The two tiles side by side, equal width
            Row(
              children: [
                Expanded(child: _CollectedTile(amount: collected)),
                const SizedBox(width: 12), // Gap between the tiles
                Expanded(child: _WishlistedTile(amount: wishlisted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// "Cataloged" tile
class _CollectedTile extends _StatTile {
  final int amount;

  const _CollectedTile({
    required this.amount
  }) : super(
    icon: LucideIcons.layers,
    title: 'Collected',
    body: '$amount cards'
  );
}

// "Wishlisted" tile
class _WishlistedTile extends _StatTile {
  final int amount;

  const _WishlistedTile({
    required this.amount
  }) : super(
    icon: LucideIcons.heart,
    title: 'Wishlisted',
    body: '$amount cards'
  );
}

// Shared layout for the tiles: icon box on the left, title and value on the right.
class _StatTile extends StatelessWidget {
  final IconData icon;
  final String title; // Muted text on top
  final String body; // Bold text below

  const _StatTile({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    // Tile background, border and padding
    return Container(
      padding: const EdgeInsets.all(12), // Space inside the tile
      decoration: BoxDecoration(
        color: AppColors.inset,
        border: Border.all(color: AppColors.insetBorder),
        borderRadius: BorderRadius.circular(12), // Tile corner radius
      ),
      child: Row(
        children: [
          // Icon box
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.inset,
              borderRadius: BorderRadius.circular(10), // Icon box corner radius
              border: Border.all(color: AppColors.insetBorder)
            ),
            child: Icon(icon, size: 18, color: AppColors.textMuted),
          ),
          const SizedBox(width: 12), // Gap between icon box and text
          // Title and value; Expanded lets long text end in "…" instead of overflowing
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tile title, e.g. "Cataloged"
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2), // Gap between title and value
                // Tile value, e.g. "263 cards"
                Text(
                  body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
