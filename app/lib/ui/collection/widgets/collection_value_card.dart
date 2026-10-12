// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/domain/models/collection/collection_overview.dart';
import 'package:app/themes/glass_theme.dart';
import 'package:app/tmp/core/utils/format.dart';
import 'package:app/ui/shared/glass/glass_card.dart';
import 'package:app/ui/shared/glass/layout.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// One game's collection: its value with the change this week, and card count, sets started and
/// completion.
class CollectionValueCard extends StatelessWidget {
  final CollectionOverview? collection; // Null while loading
  final List<CollectionOverviewSet> sets;
  final Color accent; // For the completion

  const CollectionValueCard({super.key, required this.collection, required this.sets, required this.accent});

  @override
  Widget build(BuildContext context) {
    final value = collection?.summary.value ?? 0;
    final collected = collection?.summary.collected ?? 0;
    final started = sets.where((s) => s.collected > 0).length;
    final totalCards = sets.fold(0, (n, s) => n + (s.set.cardCount ?? 0));

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Caption('Collection value'),
          const SizedBox(height: 6),
          Row(
            children: [
              Flexible(child: _Value(value)),
              const SizedBox(width: 10),
              GlassChip(
                icon: LucideIcons.trendingUp,
                label: '+${(value * 0.014).toStringAsFixed(2)} this week', // Mock: no price history yet
                color: context.glass.positive,
                filled: true,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: StatValue(value: '$collected', label: 'Cards')),
              Expanded(child: StatValue(value: '$started', label: 'Sets started')),
              Expanded(
                child: StatValue(
                  value: totalCards == 0 ? '–' : '${(collected / totalCards * 100).toStringAsFixed(1)}%',
                  label: 'Complete',
                  color: accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  final String text;

  const _Caption(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(color: context.glass.textSecondary, fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 0.5),
    );
  }
}

/// The big euro amount.
class _Value extends StatelessWidget {
  final double value;

  const _Value(this.value);

  @override
  Widget build(BuildContext context) {
    return Text(
      formatEuro(value),
      style: TextStyle(
        color: context.glass.textPrimary,
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
