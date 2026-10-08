// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/themes/glass_theme.dart';
import 'package:app/ui/shared/glass/glass_card.dart';
import 'package:flutter/material.dart';

/// Lays out children in a fixed number of equal-width columns.
class ColumnGrid extends StatelessWidget {
  final int columns;
  final double gap;
  final double runGap;
  final List<Widget> children;

  const ColumnGrid({super.key, required this.columns, this.gap = 12, this.runGap = 12, required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: runGap,
          children: [for (final child in children) SizedBox(width: width, child: child)],
        );
      },
    );
  }
}

/// Section heading placed directly on the background, with an optional widget on the right.
class SectionHeading extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const SectionHeading(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: context.glass.textPrimary, fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Big number with a small label under it, e.g. "18 / Wishlisted".
class StatValue extends StatelessWidget {
  final String value;
  final String label;
  final Color? color; // Null = the regular text color

  const StatValue({super.key, required this.value, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color ?? glass.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            height: 1.1,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: glass.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

/// Row of [StatValue]s in equal columns, in a glass card. With an optional caption above.
class StatsCard extends StatelessWidget {
  final String? caption;
  final List<StatValue> stats;

  const StatsCard({super.key, this.caption, required this.stats});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (caption != null) ...[
            Text(
              caption!,
              style: TextStyle(
                color: context.glass.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(children: [for (final stat in stats) Expanded(child: stat)]),
        ],
      ),
    );
  }
}
