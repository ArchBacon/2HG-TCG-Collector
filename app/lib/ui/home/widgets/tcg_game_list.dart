// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../tmp/core/utils/format.dart';
import '../../../tmp/shared/models/tcg.dart';
import '../../../tmp/shared/theme/app_colors.dart';

// The data shown on one game card.
class TcgGameSummary {
  final Tcg game; // Which game; also decides the name and background image
  final String latestSet; // Subtitle under the game name
  final double value; // Collection value in euros, shown in green
  final int cardCount; // Number of cataloged cards

  const TcgGameSummary({
    required this.game,
    required this.latestSet,
    required this.value,
    required this.cardCount,
  });
}

// The list of game cards on the home screen.
class TcgGameList extends StatelessWidget {
  final List<TcgGameSummary> games;
  final ValueChanged<Tcg>? onSelected; // Called with the tapped game; null = cards aren't tappable

  const TcgGameList({
    super.key,
    required this.games,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The game cards, full width
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12, // Gap between cards
          children: [
            for (final game in games)
              _TcgGameCard(
                summary: game,
                onTap: onSelected == null ? null : () => onSelected!(game.game),
              ),
          ],
        ),
      ],
    );
  }
}

// One game card: text on the left, game artwork fading in on the right.
class _TcgGameCard extends StatelessWidget {
  final TcgGameSummary summary;
  final VoidCallback? onTap;

  const _TcgGameCard({
    required this.summary,
    this.onTap,
  });

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
                    const SizedBox(height: 2), // Gap between name and latest set
                    // Latest released set
                    Text(
                      summary.latestSet,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10), // Gap between latest set and the value row
                    // Value row: collection value | layers icon + card count
                    Row(
                      children: [
                        // Collection value for this game
                        Text(
                          formatEuro(summary.value),
                          style: const TextStyle(
                            color: AppColors.brandGreen,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            fontFeatures: [FontFeature.tabularFigures()], // Equal-width digits
                          ),
                        ),
                        // Divider between value and card count (invisible while color is commented out)
                        Container(
                          width: 1,
                          height: 14,
                          margin: const EdgeInsets.symmetric(horizontal: 8), // Space on both sides of the divider
                          // color: AppColors.insetBorder,
                        ),
                        const Icon(LucideIcons.layers, size: 14, color: AppColors.textMuted), // Card count icon
                        const SizedBox(width: 6), // Gap between icon and count
                        // Number of cataloged cards
                        Text(
                          '${summary.cardCount} cards',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
