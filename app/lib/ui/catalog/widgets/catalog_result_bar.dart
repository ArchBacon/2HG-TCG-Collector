// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/domain/models/catalog/catalog_query.dart';
import 'package:app/themes/glass_theme.dart';
import 'package:app/ui/shared/glass/option_sheet.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// How the catalog shows its cards; the toggle goes through them in this order.
enum CatalogLayout {
  grid3(LucideIcons.layoutGrid, 'Bigger cards'),
  grid2(LucideIcons.grid2x2, 'List'),
  list(LucideIcons.list, 'Smaller cards');

  const CatalogLayout(this.icon, this.nextLabel);
  final IconData icon; // Shows the current layout
  final String nextLabel; // Tooltip: what tapping switches to

  CatalogLayout get next => values[(index + 1) % values.length];
}

/// Above the cards: how many match, the sort order (opens a list) and a layout toggle (3 columns,
/// 2 columns, list).
class CatalogResultBar extends StatelessWidget {
  final int count;
  final CatalogSort sort;
  final CatalogLayout layout;
  final ValueChanged<CatalogSort> onSortChanged;
  final ValueChanged<CatalogLayout> onLayoutChanged;

  const CatalogResultBar({
    super.key,
    required this.count,
    required this.sort,
    required this.layout,
    required this.onSortChanged,
    required this.onLayoutChanged,
  });

  Future<void> _pickSort(BuildContext context) async {
    final picked = await showOptionSheet(
      context,
      title: 'Sort by',
      options: [for (final s in CatalogSort.values) s.label],
      current: sort.label,
    );
    if (picked != null) onSortChanged(CatalogSort.values.firstWhere((s) => s.label == picked));
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Row(
      children: [
        Expanded(
          child: Text(
            '$count cards',
            style: TextStyle(color: glass.textSecondary, fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _pickSort(context),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Row(
              children: [
                Icon(LucideIcons.arrowUpDown, size: 15, color: glass.textSecondary),
                const SizedBox(width: 6),
                Text(sort.label, style: TextStyle(color: glass.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        ),
        IconButton(
          tooltip: layout.nextLabel,
          visualDensity: VisualDensity.compact,
          onPressed: () => onLayoutChanged(layout.next),
          icon: Icon(layout.icon, size: 18, color: glass.textSecondary),
        ),
      ],
    );
  }
}
