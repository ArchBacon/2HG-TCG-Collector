// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/themes/glass_theme.dart';
import 'package:app/ui/shared/glass/option_sheet.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum CatalogSort {
  number('Number'),
  priceHigh('Price: high to low'),
  priceLow('Price: low to high'),
  name('Name');

  const CatalogSort(this.label);
  final String label;
}

/// Above the grid: how many cards match, the sort order (opens a list) and a 3/2 columns toggle.
class CatalogResultBar extends StatelessWidget {
  final int count;
  final CatalogSort sort;
  final int columns;
  final ValueChanged<CatalogSort> onSortChanged;
  final ValueChanged<int> onColumnsChanged;

  const CatalogResultBar({
    super.key,
    required this.count,
    required this.sort,
    required this.columns,
    required this.onSortChanged,
    required this.onColumnsChanged,
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
          child: Text('$count cards', style: TextStyle(color: glass.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
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
          tooltip: columns == 3 ? 'Bigger cards' : 'Smaller cards',
          visualDensity: VisualDensity.compact,
          onPressed: () => onColumnsChanged(columns == 3 ? 2 : 3),
          icon: Icon(columns == 3 ? LucideIcons.layoutGrid : LucideIcons.grid2x2, size: 18, color: glass.textSecondary),
        ),
      ],
    );
  }
}
