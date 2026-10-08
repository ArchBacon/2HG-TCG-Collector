// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/themes/glass_theme.dart';
import 'package:app/ui/shared/glass/option_sheet.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The catalog's filters. Immutable; change with the with* methods.
class CatalogFilters {
  final String? set; // Set name; null = all
  final String? rarity; // Null = all
  final bool owned;
  final bool wishlisted;
  final bool inStore;

  const CatalogFilters({this.set, this.rarity, this.owned = false, this.wishlisted = false, this.inStore = false});

  bool matches(TcgCard card) =>
      (set == null || card.setName == set) &&
      (rarity == null || card.rarity == rarity) &&
      (!owned || card.owned > 0) &&
      (!wishlisted || card.wishlisted) &&
      (!inStore || card.inStore);

  CatalogFilters withSet(String? set) => _copy(set: () => set);
  CatalogFilters withRarity(String? rarity) => _copy(rarity: () => rarity);
  CatalogFilters withOwned(bool owned) => _copy(owned: owned);
  CatalogFilters withWishlisted(bool wishlisted) => _copy(wishlisted: wishlisted);
  CatalogFilters withInStore(bool inStore) => _copy(inStore: inStore);

  // set/rarity are passed as functions, so null can mean "clear" rather than "keep"
  CatalogFilters _copy({String? Function()? set, String? Function()? rarity, bool? owned, bool? wishlisted, bool? inStore}) {
    return CatalogFilters(
      set: set != null ? set() : this.set,
      rarity: rarity != null ? rarity() : this.rarity,
      owned: owned ?? this.owned,
      wishlisted: wishlisted ?? this.wishlisted,
      inStore: inStore ?? this.inStore,
    );
  }
}

/// Filter chips in a row that scrolls sideways (past the page padding, to the screen edges): set
/// and rarity open a list, owned / wishlisted / in store toggle.
class CatalogFilterBar extends StatelessWidget {
  final CatalogFilters filters;
  final List<String> sets;
  final List<String> rarities;
  final Color accent; // For selected chips
  final ValueChanged<CatalogFilters> onChanged;

  const CatalogFilterBar({
    super.key,
    required this.filters,
    required this.sets,
    required this.rarities,
    required this.accent,
    required this.onChanged,
  });

  static const _allSets = 'All sets';
  static const _allRarities = 'All rarities';

  Future<void> _pickSet(BuildContext context) async {
    final picked = await showOptionSheet(context, title: 'Set', options: [_allSets, ...sets], current: filters.set ?? _allSets);
    if (picked != null) onChanged(filters.withSet(picked == _allSets ? null : picked));
  }

  Future<void> _pickRarity(BuildContext context) async {
    final picked = await showOptionSheet(
      context,
      title: 'Rarity',
      options: [_allRarities, ...rarities],
      current: filters.rarity ?? _allRarities,
    );
    if (picked != null) onChanged(filters.withRarity(picked == _allRarities ? null : picked));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: [
          _FilterChip(
            label: filters.set ?? _allSets,
            dropdown: true,
            selected: filters.set != null,
            accent: accent,
            onTap: () => _pickSet(context),
          ),
          _FilterChip(
            label: filters.rarity ?? _allRarities,
            dropdown: true,
            selected: filters.rarity != null,
            accent: accent,
            onTap: () => _pickRarity(context),
          ),
          _FilterChip(
            label: 'Owned',
            icon: LucideIcons.layers,
            selected: filters.owned,
            accent: accent,
            onTap: () => onChanged(filters.withOwned(!filters.owned)),
          ),
          _FilterChip(
            label: 'Wishlisted',
            icon: LucideIcons.heart,
            selected: filters.wishlisted,
            accent: accent,
            onTap: () => onChanged(filters.withWishlisted(!filters.wishlisted)),
          ),
          _FilterChip(
            label: 'In store',
            icon: LucideIcons.shoppingCart,
            selected: filters.inStore,
            accent: accent,
            onTap: () => onChanged(filters.withInStore(!filters.inStore)),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool dropdown; // Shows a chevron: opens a list instead of toggling
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.icon,
    this.dropdown = false,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final color = selected ? accent : glass.textPrimary;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: selected ? accent.withValues(alpha: 0.18) : glass.fill,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: selected ? accent.withValues(alpha: 0.5) : glass.edge),
            ),
            child: Row(
              children: [
                if (icon != null) ...[Icon(icon, size: 14, color: color), const SizedBox(width: 6)],
                Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
                if (dropdown) ...[const SizedBox(width: 4), Icon(LucideIcons.chevronDown, size: 14, color: color)],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
