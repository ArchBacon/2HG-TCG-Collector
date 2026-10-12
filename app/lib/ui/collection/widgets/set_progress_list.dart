// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/domain/models/collection/collection_overview.dart';
import 'package:app/themes/glass_theme.dart';
import 'package:app/ui/shared/glass/glass_card.dart';
import 'package:app/ui/shared/glass/layout.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// "Sets" heading and a list of the started sets with a progress bar each, ending in a link to all
/// sets.
class SetProgressList extends StatelessWidget {
  final List<CollectionOverviewSet> sets;
  final Color accent; // Progress bar color

  const SetProgressList({super.key, required this.sets, required this.accent});

  static const _maxShown = 8;

  @override
  Widget build(BuildContext context) {
    final started = sets.where((s) => s.collected > 0).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeading(
          'Sets',
          trailing: Text(
            '${started.length} of ${sets.length} started',
            style: TextStyle(color: context.glass.textTertiary, fontSize: 13),
          ),
        ),
        GlassListCard(
          rows: [
            for (final set in started.take(_maxShown)) _SetRow(set: set, accent: accent),
            _ShowAllRow(label: 'All ${sets.length} sets'),
          ],
        ),
      ],
    );
  }
}

class _SetRow extends StatelessWidget {
  final CollectionOverviewSet set;
  final Color accent;

  const _SetRow({required this.set, required this.accent});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final total = set.set.cardCount ?? 0;

    return InkWell(
      onTap: () {}, // TODO: open the set
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    set.set.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: glass.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${set.collected}/$total',
                  style: TextStyle(
                    color: glass.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : set.collected / total,
                minHeight: 4,
                color: accent,
                backgroundColor: glass.track,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShowAllRow extends StatelessWidget {
  final String label;

  const _ShowAllRow({required this.label});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return InkWell(
      onTap: () {}, // TODO: open the full set list
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: TextStyle(color: glass.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            Icon(LucideIcons.chevronRight, size: 18, color: glass.textTertiary),
          ],
        ),
      ),
    );
  }
}
