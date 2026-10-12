// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/themes/game_palette.dart';
import 'package:app/themes/glass_theme.dart';
import 'package:app/ui/catalog/view_models/catalog_viewmodel.dart';
import 'package:app/ui/catalog/widgets/catalog_card_tile.dart';
import 'package:app/ui/catalog/widgets/catalog_filter_bar.dart';
import 'package:app/ui/catalog/widgets/catalog_result_bar.dart';
import 'package:app/ui/shared/app_state.dart';
import 'package:app/ui/shared/glass/glass_card.dart';
import 'package:app/ui/shared/glass/glass_scaffold.dart';
import 'package:app/ui/shared/glass/layout.dart';
import 'package:flutter/material.dart';

/// Catalog tab: one game's cards. Filter chips, the result count with sorting and grid density, and
/// the cards as a grid. Filters on the search in the header ([cardSearch]) too. Filters, sorting
/// and density are view state, kept here; the cards come from the view model.
class CatalogScreen extends StatefulWidget {
  final CatalogViewModel viewModel;

  const CatalogScreen({super.key, required this.viewModel});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  var _filters = const CatalogFilters();
  var _sort = CatalogSort.number;
  var _columns = 3;

  // Rebuild when the cards load, and when the search in the header changes
  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_rebuild);
    cardSearch.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_rebuild);
    cardSearch.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  List<TcgCard> _visibleCards(List<TcgCard> all) {
    final search = cardSearch.value.trim().toLowerCase();
    final cards = all
        .where((c) => search.isEmpty || c.name.toLowerCase().contains(search))
        .where(_filters.matches)
        .toList();
    switch (_sort) {
      case CatalogSort.number:
        break; // Already in set/number order
      case CatalogSort.priceHigh:
        cards.sort((a, b) => b.price.compareTo(a.price));
      case CatalogSort.priceLow:
        cards.sort((a, b) => a.price.compareTo(b.price));
      case CatalogSort.name:
        cards.sort((a, b) => a.name.compareTo(b.name));
    }
    return cards;
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    final accent = GamePalette.of(context, viewModel.tcg).accent;
    final cards = _visibleCards(viewModel.cards);

    return GlassScaffold(
      title: 'Catalog',
      game: viewModel.tcg,
      children: [
        CatalogFilterBar(
          filters: _filters,
          sets: viewModel.sets,
          rarities: viewModel.rarities,
          accent: accent,
          onChanged: (filters) => setState(() => _filters = filters),
        ),
        const SizedBox(height: 16),
        CatalogResultBar(
          count: cards.length,
          sort: _sort,
          columns: _columns,
          onSortChanged: (sort) => setState(() => _sort = sort),
          onColumnsChanged: (columns) => setState(() => _columns = columns),
        ),
        const SizedBox(height: 8),
        if (cards.isEmpty)
          const _NoResults()
        else
          ColumnGrid(
            columns: _columns,
            gap: 10,
            runGap: 16,
            children: [for (final card in cards) CatalogCardTile(card: card, accent: accent)],
          ),
      ],
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('No cards match these filters', style: TextStyle(color: context.glass.textSecondary)),
        ),
      ),
    );
  }
}
