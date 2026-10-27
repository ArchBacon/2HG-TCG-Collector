// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/themes/game_palette.dart';
import 'package:app/themes/glass_theme.dart';
import 'package:app/ui/catalog/view_models/catalog_viewmodel.dart';
import 'package:app/ui/catalog/widgets/catalog_card_row.dart';
import 'package:app/ui/catalog/widgets/catalog_card_tile.dart';
import 'package:app/ui/catalog/widgets/catalog_filter_bar.dart';
import 'package:app/ui/catalog/widgets/catalog_result_bar.dart';
import 'package:app/ui/collection/widgets/recently_added_row.dart';
import 'package:app/ui/shared/glass/glass_card.dart';
import 'package:app/ui/shared/glass/glass_scaffold.dart';
import 'package:app/ui/shared/glass/layout.dart';
import 'package:app/ui/shared/glass/loading_indicator.dart';
import 'package:flutter/material.dart';

/// Catalog tab: one game's cards, with the cards added to the collection last on top. Filter chips,
/// the result count with sorting and layout, and the cards as a grid or list, a page at a time: the
/// next page loads when scrolling near the bottom. Filters, sorting and the search in the header
/// are applied by the view model; the layout is view state, kept here.
///
/// Also a collection's page, for a view model of a collection: with its [title] and [trailingActions].
class CatalogScreen extends StatefulWidget {
  final CatalogViewModel viewModel;
  final String title;
  final List<Widget>? trailingActions; // Extra header buttons, after the cart

  const CatalogScreen({super.key, required this.viewModel, this.title = 'Catalog', this.trailingActions});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  var _layout = CatalogLayout.grid3;

  // How close to the bottom (in pixels) the next page starts loading, so it's usually there
  // before the end is reached
  static const _loadMoreDistance = 800.0;

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  int get _columns => _layout == CatalogLayout.grid2 ? 2 : 3;

  bool _onScroll(ScrollNotification notification) {
    if (notification.metrics.axis == Axis.vertical && notification.metrics.extentAfter < _loadMoreDistance) {
      widget.viewModel.loadMore();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    final accent = GamePalette.of(context, viewModel.tcg).accent;
    final cards = viewModel.cards;

    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: GlassScaffold(
        title: widget.title,
        game: viewModel.tcg,
        trailingActions: widget.trailingActions,
        search: viewModel.collectionId == null ? null : viewModel.search,
        searchHint: viewModel.collectionId == null ? null : 'Search collection',
        children: [
          if (viewModel.recentlyAdded.isNotEmpty) ...[
            RecentlyAddedRow(cards: viewModel.recentlyAdded),
            const SizedBox(height: 24),
          ],
          CatalogFilterBar(
            filters: viewModel.filters,
            sets: viewModel.sets,
            rarities: viewModel.rarities,
            artists: viewModel.artists,
            accent: accent,
            showOwned: viewModel.collectionId == null, // A collection's cards all are
            onChanged: (filters) => viewModel.filters = filters,
          ),
          const SizedBox(height: 16),
          CatalogResultBar(
            count: viewModel.total,
            sort: viewModel.sort,
            layout: _layout,
            onSortChanged: (sort) => viewModel.sort = sort,
            onLayoutChanged: (layout) => setState(() => _layout = layout),
          ),
          const SizedBox(height: 8),
          if (viewModel.loading)
            LoadingSection(color: accent)
          else if (cards.isEmpty)
            _NoResults(
              failed: viewModel.failed,
              message: viewModel.collectionId != null && viewModel.filters.isEmpty && viewModel.search.value.trim().isEmpty
                  ? 'No ${viewModel.tcg.displayName} cards in here yet. Add them from a card\'s page.'
                  : 'No cards match these filters',
            )
          else ...[
            if (_layout == CatalogLayout.list)
              for (final card in cards)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: CatalogCardRow(card: card, accent: accent),
                )
            else
              // A row per list item, so only the rows on screen are built (and load their images)
              for (var i = 0; i < cards.length; i += _columns)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ColumnGrid(
                    columns: _columns,
                    gap: 10,
                    children: [
                      for (final card in cards.skip(i).take(_columns)) CatalogCardTile(card: card, accent: accent),
                    ],
                  ),
                ),
            if (viewModel.loadingMore)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(child: LoadingIndicator(color: accent)),
              ),
          ],
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  final bool failed; // The cards couldn't be loaded, rather than none matching
  final String message; // When none match

  const _NoResults({required this.failed, required this.message});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            failed ? "Couldn't load the cards" : message,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.glass.textSecondary),
          ),
        ),
      ),
    );
  }
}
