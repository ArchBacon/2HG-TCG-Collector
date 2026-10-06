// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/domain/models/collection/collection_overview.dart';
import 'package:app/domain/models/tcg/tcg.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../config/assets.dart';
import '../../../tmp/shared/theme/app_colors.dart';

// Turns an image path from the API (e.g. "/pokemon/sets/icons/sv01.webp") into something to draw.
typedef ImageResolver = ImageProvider Function(String path);

// All set blocks of one game, one card per block, newest block first.
class SetBlockList extends StatelessWidget {
  final Tcg tcg; // Used for the block title fallback and the placeholder set image
  final List<CollectionOverviewBlock> blocks;
  final ImageResolver? imageResolver; // null = no block icons
  final ValueChanged<CollectionOverviewSet>? onSetSelected; // Set row tap; null = rows aren't tappable

  const SetBlockList({
    super.key,
    required this.tcg,
    required this.blocks,
    this.imageResolver,
    this.onSetSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12, // Gap between block cards
      children: [
        for (final block in blocks)
          SetBlock(
            // Keeps each block's expanded state attached to that block if the list changes
            key: ValueKey(block.block),
            tcg: tcg,
            block: block,
            imageResolver: imageResolver,
            onSetSelected: onSetSelected,
          ),
      ],
    );
  }
}

// One block card: a header with the block icon and name that collapses/expands the block, then a
// row per set. Starts collapsed.
class SetBlock extends StatefulWidget {
  final Tcg tcg;
  final CollectionOverviewBlock block;
  final ImageResolver? imageResolver;
  final ValueChanged<CollectionOverviewSet>? onSetSelected;

  const SetBlock({
    super.key,
    required this.tcg,
    required this.block,
    this.imageResolver,
    this.onSetSelected,
  });

  @override
  State<SetBlock> createState() => _SetBlockState();
}

class _SetBlockState extends State<SetBlock> {
  bool _expanded = true;

  // The API only sends the block's code (e.g. "sv", or MTG's parent set code), so the block is
  // represented by the set whose code matches (MTG), or else its oldest set, which is usually its
  // namesake ("Scarlet & Violet"). Games without blocks have none.
  TcgSet? get _namesake {
    final code = widget.block.block;
    if (code == null || widget.block.sets.isEmpty) return null;

    final sets = widget.block.sets.map((s) => s.set);
    return sets.where((s) => s.code == code).firstOrNull ?? sets.last;
  }

  @override
  Widget build(BuildContext context) {
    final namesake = _namesake;
    final title = namesake?.name ?? widget.tcg.displayName;
    final iconPath = namesake?.images['icon'];
    final icon = iconPath == null ? null : widget.imageResolver?.call(iconPath);
    final collected = widget.block.sets.fold(0, (sum, s) => sum + s.collected);

    // Same shadow as the other cards; Material's own elevation shadow looks different.
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16), // Must match the card's corner radius below
        boxShadow: const [
          BoxShadow(color: Color(0x59000000), blurRadius: 16, offset: Offset(0, 4)), // Black 35%, soft, 4px down
        ],
      ),
      child: Material(
        color: AppColors.card, // Card background
        clipBehavior: Clip.antiAlias, // Keeps the row ripples inside the rounded corners
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // Corner radius
          side: const BorderSide(color: AppColors.cardBorder), // 1px border
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: icon | block name | chevron | collected pill. Tapping anywhere on it collapses/expands the block.
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), // Space around the header
                child: Row(
                  children: [
                    // Block icon, only when the API has one and we can load it
                    if (icon != null) ...[
                      Image(
                        image: icon,
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain, // Whole icon visible, no cropping
                        excludeFromSemantics: true, // The block name next to it says the same
                        errorBuilder: (context, error, stackTrace) => const SizedBox(width: 24, height: 24),
                      ),
                      const SizedBox(width: 10), // Gap between icon and name
                    ],
                    // Name and chevron together take all the space left of the pill, which pushes the pill
                    // to the far right while the chevron stays right after the name
                    Expanded(
                      child: Row(
                        children: [
                          // Block name; Flexible lets long names end in "…" instead of pushing the chevron off
                          Flexible(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6), // Gap between name and chevron
                          // Chevron: points right when collapsed, turns down when expanded
                          AnimatedRotation(
                            turns: _expanded ? 0.25 : 0, // 0.25 = a quarter turn clockwise
                            duration: const Duration(milliseconds: 200),
                            child: const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10), // Minimum gap between chevron and pill
                    _CountPill(count: collected),
                  ],
                ),
              ),
            ),
            // The set rows; animates the card's height when opening/closing
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter, // Rows slide out from under the header
              child: _expanded
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 8), // Space below the last row
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final set in widget.block.sets)
                            SetEntry(
                              image: Assets.images.cardbackFor(widget.tcg), // Placeholder until set logos are loaded from the API
                              name: set.set.name,
                              collected: set.collected,
                              total: set.set.cardCount ?? 0,
                              onTap: widget.onSetSelected == null ? null : () => widget.onSetSelected!(set),
                            ),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity), // Collapsed: no rows, full width so the card doesn't shrink
            ),
          ],
        ),
      ),
    );
  }
}

// Pill on the right of the block header with the number of cards collected in the block.
class _CountPill extends StatelessWidget {
  final int count;

  const _CountPill({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), // Space inside the pill
      decoration: BoxDecoration(
        color: AppColors.inset,
        border: Border.all(color: AppColors.insetBorder),
        borderRadius: BorderRadius.circular(6), // Pill corner radius
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
          fontFeatures: [FontFeature.tabularFigures()], // Equal-width digits
        ),
      ),
    );
  }
}

// One set row: logo on the left; name, "6 / 188 cards", percentage and progress bar on the right.
class SetEntry extends StatelessWidget {
  final String? image; // Asset path of the set logo; null shows an empty box
  final String name;
  final int collected; // Distinct cards collected
  final int total; // Cards in the set
  final VoidCallback? onTap;

  const SetEntry({
    super.key,
    required this.image,
    required this.name,
    required this.collected,
    required this.total,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : (collected / total).clamp(0.0, 1.0);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // Space around the row; vertical also sets the row height
        child: Row(
          children: [
            // Set logo box
            Container(
              width: 56,
              height: 36,
              clipBehavior: Clip.antiAlias, // Cuts the image off at the rounded corners
              decoration: BoxDecoration(
                color: AppColors.inset,
                border: Border.all(color: AppColors.insetBorder),
                borderRadius: BorderRadius.circular(8), // Logo box corner radius
              ),
              child: image == null
                  ? null
                  : Image.asset(
                      image!,
                      fit: BoxFit.cover, // Fills the box, cropping the image where needed
                      excludeFromSemantics: true, // The set name next to it says the same
                    ),
            ),
            const SizedBox(width: 12), // Gap between logo and text
            // Name, counts and progress bar
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Set name
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2), // Gap between name and counts
                  // Counts | percentage
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$collected / $total cards',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            fontFeatures: [FontFeature.tabularFigures()], // Equal-width digits
                          ),
                        ),
                      ),
                      Text(
                        '${(progress * 100).floor()}%', // Rounded down, so 100% means complete
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6), // Gap between counts and progress bar
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2), // Rounded bar ends
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4, // Bar thickness
                      color: AppColors.brandGreen,
                      backgroundColor: AppColors.insetBorder,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
