// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/ui/shared/new_badge.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../tmp/shared/models/tcg.dart';
import '../../../tmp/shared/theme/app_colors.dart';

// The data shown on one game card.
class WishlistGameSummary {
  final Tcg game; // Which game; also decides the name and background image
  final int cardCount; // Number of wishlisted cards
  final int availableCount; // Wishlisted cards that are for sale in the store
  final int newCount; // Of those, cards recently added to the store

  const WishlistGameSummary({
    required this.game,
    required this.cardCount,
    required this.availableCount,
    required this.newCount,
  });
}

// The list of game cards on the wishlist screen.
class WishlistGameList extends StatelessWidget {
  final List<WishlistGameSummary> games;
  final ValueChanged<Tcg>? onSelected; // Called with the tapped game; null = cards aren't tappable

  const WishlistGameList({
    super.key,
    required this.games,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    // The game cards, full width
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12, // Gap between cards
      children: [
        for (final game in games)
          _WishlistGameCard(
            summary: game,
            onTap: onSelected == null ? null : () => onSelected!(game.game),
          ),
      ],
    );
  }
}

// One game card: text on the left, game artwork fading in on the right.
class _WishlistGameCard extends StatelessWidget {
  final WishlistGameSummary summary;
  final VoidCallback? onTap;

  const _WishlistGameCard({
    required this.summary,
    this.onTap,
  });

  static const _mutedStyle = TextStyle(
    color: AppColors.textMuted,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  @override
  Widget build(BuildContext context) {
    // Same shadow as the collection value card; Material's own elevation shadow looks different.
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16), // Must match the card's corner radius below
        boxShadow: const [
          BoxShadow(color: Color(0x59000000), blurRadius: 16, offset: Offset(0, 4)), // Black 35%, soft, 4px down
        ],
      ),
      // The card itself: background, border, rounded corners, and clipping of the artwork
      child: Material(
        color: AppColors.card, // Card background
        clipBehavior: Clip.antiAlias, // Cuts the artwork off at the rounded corners
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // Corner radius
          side: const BorderSide(color: AppColors.cardBorder), // 1px border
        ),
        // Tap handling with the ripple effect
        child: InkWell(
          onTap: onTap,
          // Artwork in the back, text on top
          child: Stack(
            children: [
              // Game artwork on the right 2/5 of the card, fading into the card towards the left.
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerRight, // Pins the artwork to the right edge
                  child: FractionallySizedBox(
                    widthFactor: 2 / 5, // Artwork width, as a fraction of the card width
                    heightFactor: 1, // Full card height
                    // Shifted right so the artwork's own frame falls outside the card and is clipped.
                    child: FractionalTranslation(
                      translation: const Offset(0.08, 0), // 8% of the artwork width; raise for thicker frames
                      // The fade: makes the artwork transparent on the left, visible on the right
                      child: ShaderMask(
                        blendMode: BlendMode.dstIn,
                        shaderCallback: (bounds) => const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Color(0x00FFFFFF), Color(0x80FFFFFF)], // Opacity: 0% on the left, 50% on the right
                          stops: [0, 1], // Where the fade starts/ends (0 = left edge, 1 = right edge)
                        ).createShader(bounds),
                        child: Image.asset(
                          summary.game.imageAsset,
                          fit: BoxFit.cover, // Fills the area, cropping the image where needed
                          excludeFromSemantics: true, // Decorative; screen readers skip it
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Text content on the left
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), // Space around the text; vertical also sets the card height
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Game name
                    Text(
                      summary.game.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis, // Long names end in "…"
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8), // Gap between name and the stats
                    // Stats row: heart + wishlisted count, cart + store count (hidden when 0)
                    Row(
                      children: [
                        _iconStat(LucideIcons.heart, '${summary.cardCount} cards'),
                        if (summary.availableCount > 0) ...[
                          const SizedBox(width: 16), // Gap between the two stats
                          _iconStat(LucideIcons.shoppingCart, '${summary.availableCount} in store'),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // "New" badge in the top-right corner, on top of the artwork. Positioned, so it doesn't
              // change the card height.
              if (summary.newCount > 0)
                Positioned(
                  top: 12,
                  right: 12,
                  child: NewBadge(label: '${summary.newCount} new'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Small muted icon followed by its label.
  Widget _iconStat(IconData icon, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: AppColors.textMuted),
      const SizedBox(width: 6), // Gap between icon and label
      Text(label, style: _mutedStyle),
    ],
  );
}
