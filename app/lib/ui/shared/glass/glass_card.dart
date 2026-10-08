// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/themes/glass_theme.dart';
import 'package:flutter/material.dart';

/// Glass panel: a translucent fill, lighter at the top like light catching the glass, and a thin
/// edge. No live blur (the background is already blurred) and no drop shadow: through a
/// translucent fill a shadow shows as a smudge.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: glass.edge),
    );

    return Material(
      type: MaterialType.transparency,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: ShapeDecoration(
          shape: shape,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [glass.cardTop, glass.cardBottom],
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Glass card holding rows, with thin dividers between them.
class GlassListCard extends StatelessWidget {
  final List<Widget> rows;
  final double dividerIndent;

  const GlassListCard({super.key, required this.rows, this.dividerIndent = 16});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, row) in rows.indexed) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: context.glass.divider, indent: dividerIndent),
            row,
          ],
        ],
      ),
    );
  }
}

/// Small rounded label on glass, e.g. "3 new".
class GlassChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color; // Null = the regular text color
  final bool filled; // Filled with the color, for emphasis

  const GlassChip({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final color = this.color ?? glass.textPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? color.withValues(alpha: 0.2) : glass.fill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: filled ? color.withValues(alpha: 0.45) : glass.edge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
          ],
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
