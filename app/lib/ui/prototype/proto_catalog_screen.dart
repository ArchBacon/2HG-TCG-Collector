// Copyright 2026 Christian Delicaat. All rights reserved.

// PROTOTYPE: Catalog tab. Every card of the current game as a grid, with search, filter chips and
// sorting (all of them work, on the generated data). With "All games" picked: pick a game first.

import 'package:app/tmp/core/utils/format.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/ui/prototype/game_switcher.dart';
import 'package:app/ui/prototype/glass.dart';
import 'package:app/ui/prototype/proto_common.dart';
import 'package:app/ui/prototype/proto_data.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ProtoCatalogScreen extends StatelessWidget {
  const ProtoCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: protoGame,
      // Keyed by game, so the filters reset when the game changes
      builder: (context, game, _) => game == null ? const _PickGame() : _Catalog(key: ValueKey(game), game: game),
    );
  }
}

enum _Sort {
  number('Number'),
  priceHigh('Price: high to low'),
  priceLow('Price: low to high'),
  name('Name');

  const _Sort(this.label);
  final String label;
}

class _Catalog extends StatefulWidget {
  final Tcg game;

  const _Catalog({super.key, required this.game});

  @override
  State<_Catalog> createState() => _CatalogState();
}

class _CatalogState extends State<_Catalog> {
  var _search = '';
  String? _set; // Set name; null = all
  String? _rarity; // Null = all
  var _owned = false;
  var _wishlisted = false;
  var _inStore = false;
  var _sort = _Sort.number;
  var _columns = 3;

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final palette = GamePalette.of(game);
    final all = ProtoData.catalog(game);
    final sets = {for (final c in all) c.setName}.toList();
    final rarities = {for (final c in all) c.rarity!}.toList();

    final cards = all.where((c) {
      if (_search.isNotEmpty && !c.name.toLowerCase().contains(_search.toLowerCase())) return false;
      if (_set != null && c.setName != _set) return false;
      if (_rarity != null && c.rarity != _rarity) return false;
      if (_owned && c.owned == 0) return false;
      if (_wishlisted && !c.wishlisted) return false;
      if (_inStore && !c.inStore) return false;
      return true;
    }).toList();
    switch (_sort) {
      case _Sort.number:
        break; // Already in set/number order
      case _Sort.priceHigh:
        cards.sort((a, b) => b.price.compareTo(a.price));
      case _Sort.priceLow:
        cards.sort((a, b) => a.price.compareTo(b.price));
      case _Sort.name:
        cards.sort((a, b) => a.name.compareTo(b.name));
    }

    return ProtoScaffold(
      title: 'Catalog',
      game: game,
      children: [
        // Search
        TextField(
          onChanged: (value) => setState(() => _search = value),
          style: TextStyle(color: GlassText.primary, fontSize: 15),
          cursorColor: palette.accent,
          decoration: InputDecoration(
            hintText: 'Search ${game.displayName}',
            hintStyle: TextStyle(color: GlassText.tertiary, fontSize: 15),
            prefixIcon: Icon(LucideIcons.search, size: 18, color: GlassText.secondary),
            filled: true,
            fillColor: GlassColors.of(context).fill,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: GlassColors.current.edge),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: GlassColors.current.edge),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: palette.accent.withValues(alpha: 0.6)),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Filters; the row runs past the page padding so it scrolls edge to edge
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              _FilterChip(
                label: _set ?? 'All sets',
                dropdown: true,
                selected: _set != null,
                accent: palette.accent,
                onTap: () async {
                  final picked = await _pick(context, 'Set', ['All sets', ...sets], _set ?? 'All sets');
                  if (picked != null) setState(() => _set = picked == 'All sets' ? null : picked);
                },
              ),
              _FilterChip(
                label: _rarity ?? 'All rarities',
                dropdown: true,
                selected: _rarity != null,
                accent: palette.accent,
                onTap: () async {
                  final picked = await _pick(context, 'Rarity', ['All rarities', ...rarities], _rarity ?? 'All rarities');
                  if (picked != null) setState(() => _rarity = picked == 'All rarities' ? null : picked);
                },
              ),
              _FilterChip(
                label: 'Owned',
                icon: LucideIcons.layers,
                selected: _owned,
                accent: palette.accent,
                onTap: () => setState(() => _owned = !_owned),
              ),
              _FilterChip(
                label: 'Wishlisted',
                icon: LucideIcons.heart,
                selected: _wishlisted,
                accent: palette.accent,
                onTap: () => setState(() => _wishlisted = !_wishlisted),
              ),
              _FilterChip(
                label: 'In store',
                icon: LucideIcons.shoppingCart,
                selected: _inStore,
                accent: palette.accent,
                onTap: () => setState(() => _inStore = !_inStore),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Result count, sort and density
        Row(
          children: [
            Expanded(
              child: Text(
                '${cards.length} cards',
                style: TextStyle(color: GlassText.secondary, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () async {
                final labels = [for (final s in _Sort.values) s.label];
                final picked = await _pick(context, 'Sort by', labels, _sort.label);
                if (picked != null) setState(() => _sort = _Sort.values.firstWhere((s) => s.label == picked));
              },
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Row(
                  children: [
                    Icon(LucideIcons.arrowUpDown, size: 15, color: GlassText.secondary),
                    const SizedBox(width: 6),
                    Text(_sort.label, style: TextStyle(color: GlassText.secondary, fontSize: 13)),
                  ],
                ),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () => setState(() => _columns = _columns == 3 ? 2 : 3),
              icon: Icon(_columns == 3 ? LucideIcons.layoutGrid : LucideIcons.grid2x2, size: 18, color: GlassText.secondary),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // The grid
        if (cards.isEmpty)
          GlassCard(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('No cards match these filters', style: TextStyle(color: GlassText.secondary))),
            ),
          )
        else
          ProtoGrid(
            columns: _columns,
            gap: 10,
            runGap: 16,
            children: [for (final card in cards) _CatalogCard(card: card, accent: palette.accent)],
          ),
      ],
    );
  }
}

// Frosted sheet with a list of options; returns the picked one.
Future<String?> _pick(BuildContext context, String title, List<String> options, String current) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: ProtoTheme.isDark ? const Color(0xF010141A) : const Color(0xF0F4F6FA),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    // Size to the content instead of the default cap of 9/16 of the screen; scrolls when longer
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text(title, style: TextStyle(color: GlassText.primary, fontSize: 17, fontWeight: FontWeight.w700)),
            ),
            for (final option in options)
              ListTile(
                title: Text(option, style: TextStyle(color: GlassText.primary)),
                trailing: option == current ? Icon(LucideIcons.check, size: 18, color: GlassText.primary) : null,
                onTap: () => Navigator.pop(context, option),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
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
    final color = selected ? accent : GlassText.primary;

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
              color: selected ? accent.withValues(alpha: 0.18) : GlassColors.of(context).fill,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: selected ? accent.withValues(alpha: 0.5) : GlassColors.current.edge),
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

// Card image with markers (owned count top-left, wishlisted top-right), name, number and price.
class _CatalogCard extends StatelessWidget {
  final ProtoCard card;
  final Color accent;

  const _CatalogCard({required this.card, required this.accent});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openCard(context, card),
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CardThumb(game: card.game, width: constraints.maxWidth, radius: 8),
                if (card.owned > 0)
                  Positioned(
                    top: 5,
                    left: 5,
                    child: _Badge(icon: LucideIcons.check, label: '${card.owned}', color: GlassText.positive),
                  ),
                if (card.wishlisted)
                  Positioned(top: 5, right: 5, child: _Badge(icon: LucideIcons.heart, color: accent)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              card.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: GlassText.primary, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 1),
            Row(
              children: [
                Expanded(
                  child: Text(
                    card.number,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: GlassText.tertiary, fontSize: 11),
                  ),
                ),
                Text(
                  formatEuro(card.price),
                  style: TextStyle(color: GlassText.secondary, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String? label;
  final Color color;

  const _Badge({required this.icon, this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xCC0A0D12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          if (label != null) ...[
            const SizedBox(width: 3),
            Text(label!, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
          ],
        ],
      ),
    );
  }
}

// "All games": the catalog is per game, so pick one first.
class _PickGame extends StatelessWidget {
  const _PickGame();

  @override
  Widget build(BuildContext context) {
    return ProtoScaffold(
      title: 'Catalog',
      game: null,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(4, 4, 4, 16),
          child: Text(
            'Which catalog do you want to browse?',
            style: TextStyle(color: GlassText.primary, fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ),
        ProtoGrid(
          columns: 2,
          children: [
            for (final game in Tcg.values)
              ProtoGameTile(
                game: game,
                stats: [(LucideIcons.library, '${ProtoData.catalog(game).length} cards')],
                onTap: () => protoGame.value = game,
              ),
          ],
        ),
      ],
    );
  }
}
