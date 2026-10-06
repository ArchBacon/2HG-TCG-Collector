// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:flutter/material.dart';

import '../../../tmp/shared/models/tcg.dart';
import '../../../tmp/shared/theme/app_colors.dart';

// Same background colors as the CollectionSummaryCard (lib/ui/shared/collection_value.dart).
const _cardTop = Color(0xFF141923); // Background color at the top of the card
const _cardBottom = Color(0xFF171C24); // Background color at the bottom of the card
const _cardGlow = Color(0x1A5CB85C); // brand green (0xFF5CB85C) at 10%

// One wishlisted card that was recently added to the store.
class NewInStoreCard {
  final Tcg game; // Which game; also picks the placeholder image
  final String name; // Card name
  final String number; // Collector number, shown under the name on the image

  const NewInStoreCard({
    required this.game,
    required this.name,
    required this.number,
  });
}

// Card with a title and a horizontal row of card thumbnails.
class NewInStoreCarousel extends StatelessWidget {
  final List<NewInStoreCard> cards;
  final ValueChanged<NewInStoreCard>? onSelected; // Called with the tapped card; null = not tappable

  const NewInStoreCarousel({
    super.key,
    required this.cards,
    this.onSelected,
  });

  static const _thumbWidth = 108.0;
  static const _thumbHeight = _thumbWidth * 204 / 146; // Card proportions (same as the cardback images)
  static const _padding = 12.0; // Space between the card edge and the thumbnails
  static const _bottomPadding = 20.0; // Below the thumbnails; the scroll indicator sits centered in it

  @override
  Widget build(BuildContext context) {
    // Same background as the CollectionSummaryCard: a dark base that lightens slightly downwards, and a
    // faint brand-green glow from the right.
    // Outer layer: base gradient, border, rounded corners and shadow
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_cardTop, _cardBottom],
        ),
        borderRadius: BorderRadius.circular(16), // Corner radius
        border: Border.all(color: AppColors.cardBorder), // 1px border
        boxShadow: const [
          BoxShadow(color: Color(0x59000000), blurRadius: 16, offset: Offset(0, 4)), // Black 35%, soft, 4px down
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16), // Cuts the thumbnails off at the rounded corners
        // Inner layer: the green glow
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.9, 0.5), // Glow center: x -1..1 (left..right), y -1..1 (top..bottom)
              radius: 1.5, // Glow size; larger = spreads further left
              colors: [_cardGlow, Color(0x005CB85C)], // From the glow color to fully transparent
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Padding(
                padding: EdgeInsets.fromLTRB(_padding + 4, _padding + 2, _padding, 0), // Slightly more inset than the thumbnails, to clear the rounded corner
                child: Text(
                  'New in store',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // The thumbnails, fading out towards the card edges while scrolling
              SizedBox(
                height: _thumbHeight + _bottomPadding + 8, // Top gap + thumbnail + bottom padding
                child: _EdgeFadeList(
                  solidWidth: _padding / 2,
                  fadeWidth: 32,
                  padding: const EdgeInsets.fromLTRB(_padding, 8, _padding, _bottomPadding), // Top is the gap under the title; also keeps the thumbnail shadows from being cut off
                  itemCount: cards.length,
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    return _Thumbnail(
                      card: card,
                      width: _thumbWidth,
                      height: _thumbHeight,
                      onTap: onSelected == null ? null : () => onSelected!(card),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Horizontal list whose sides fade out, but only where there's more to scroll to: the left fade
// appears once scrolled away from the start, the right fade disappears when reaching the end. That
// way the first and last items aren't faded at rest, however wide the fade is.
class _EdgeFadeList extends StatefulWidget {
  final double solidWidth; // Fully hidden strip at each edge, before the fade starts, in pixels
  final double fadeWidth; // Width of each fade, including the solid strip, in pixels
  final EdgeInsets padding;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  const _EdgeFadeList({
    required this.solidWidth,
    required this.fadeWidth,
    required this.padding,
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  State<_EdgeFadeList> createState() => _EdgeFadeListState();
}

class _EdgeFadeListState extends State<_EdgeFadeList> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    // The controller only notifies on scroll, so rebuild once after the first layout to show the
    // scroll indicator and the fades for the starting position.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        // How far each fade is "on", from 0 to 1. It builds up over the first fadeWidth pixels of
        // scrolling, so it eases in instead of popping on. Before the first layout there's no
        // scroll position yet: start without a left fade and with a right fade.
        var left = 0.0;
        var right = 1.0;
        // Scroll indicator: thumb size and position, both as fractions of the track (null = hidden)
        double? thumbSize;
        var thumbPosition = 0.0;
        if (_controller.hasClients && _controller.position.hasContentDimensions) {
          final position = _controller.position;
          left = (position.pixels / widget.fadeWidth).clamp(0.0, 1.0);
          right = ((position.maxScrollExtent - position.pixels) / widget.fadeWidth).clamp(0.0, 1.0);

          if (position.maxScrollExtent > 0) {
            thumbSize = position.viewportDimension / (position.viewportDimension + position.maxScrollExtent);
            thumbPosition = (position.pixels / position.maxScrollExtent).clamp(0.0, 1.0);
          }
        }

        final list = ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (bounds) {
            // Widths as fractions of the list width
            final solid = widget.solidWidth / bounds.width;
            final edge = widget.fadeWidth / bounds.width;
            final leftEdge = Colors.white.withValues(alpha: 1 - left); // Hidden when fully faded
            final rightEdge = Colors.white.withValues(alpha: 1 - right);
            return LinearGradient(
              // Solid strip at each edge, then a fade to fully visible
              colors: [leftEdge, leftEdge, Colors.white, Colors.white, rightEdge, rightEdge],
              stops: [0, solid, edge, 1 - edge, 1 - solid, 1],
            ).createShader(bounds);
          },
          child: child,
        );

        return Stack(
          children: [
            Positioned.fill(child: list),
            // Thin scroll indicator, centered in the bottom padding. Its ends line up with where the
            // side fades end, so it spans the fully visible part of the list.
            if (thumbSize != null)
              Positioned(
                left: widget.fadeWidth,
                right: widget.fadeWidth,
                bottom: (widget.padding.bottom - 2) / 2,
                height: 2,
                child: DecoratedBox(
                  // Track
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder, // White 6%
                    borderRadius: BorderRadius.circular(1),
                  ),
                  // Thumb
                  child: Align(
                    alignment: Alignment(thumbPosition * 2 - 1, 0), // -1 = left end, 1 = right end
                    child: FractionallySizedBox(
                      widthFactor: thumbSize,
                      heightFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.textMuted.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        padding: widget.padding,
        itemCount: widget.itemCount,
        separatorBuilder: (context, index) => const SizedBox(width: 10), // Gap between items
        itemBuilder: widget.itemBuilder,
      ),
    );
  }
}

// One card: the image, with name + number over a dark fade at the bottom.
class _Thumbnail extends StatelessWidget {
  final NewInStoreCard card;
  final double width;
  final double height;
  final VoidCallback? onTap;

  const _Thumbnail({
    required this.card,
    required this.width,
    required this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(color: Color(0x59000000), blurRadius: 8, offset: Offset(0, 2)), // Black 35%, like the badge
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8), // Card corners
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Card image. TODO: use the card's own image once card images are loaded from the API.
                Image.asset(
                  card.game.imageAsset,
                  fit: BoxFit.cover,
                  semanticLabel: card.name,
                ),
                // Dark fade over the bottom, so the text on top stays readable
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xE6000000), Color(0xB3000000), Color(0x00000000)], // Black 90% -> 70% -> transparent
                      stops: [0, 0.3, 0.75], // Stays dark behind the text, then fades out 3/4 of the way up
                    ),
                  ),
                ),
                // Name and number at the bottom
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        card.number,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 11, fontWeight: FontWeight.w500), // White 70%
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
