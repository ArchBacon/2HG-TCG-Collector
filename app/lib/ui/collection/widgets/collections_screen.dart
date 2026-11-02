// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/domain/models/collection/list_kind.dart';
import 'package:app/routing/routes.dart';
import 'package:app/themes/game_palette.dart';
import 'package:app/themes/glass_theme.dart';
import 'package:app/ui/catalog/view_models/catalog_viewmodel.dart';
import 'package:app/ui/catalog/widgets/catalog_card_tile.dart';
import 'package:app/ui/collection/view_models/collections_viewmodel.dart';
import 'package:app/ui/collection/widgets/collection_card.dart';
import 'package:app/ui/collection/widgets/collection_dialogs.dart';
import 'package:app/ui/shared/glass/glass_card.dart';
import 'package:app/ui/shared/glass/glass_scaffold.dart';
import 'package:app/ui/shared/glass/layout.dart';
import 'package:app/ui/shared/glass/loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Collection or Wishlist tab: a card per list of that kind the user made, with its counts and value
/// for the selected game. Opens a list, and makes new ones. The header's search finds cards in any
/// of them: while there's text, the matching cards show instead of the lists (and [header]).
class CollectionsScreen extends StatelessWidget {
  final CollectionsViewModel viewModel;
  final CatalogViewModel searchViewModel; // The cards in the lists, found by the search
  final Widget? header; // Above the lists

  const CollectionsScreen({super.key, required this.viewModel, required this.searchViewModel, this.header});

  static const _columns = 3;

  Future<void> _create(BuildContext context, Color accent) async {
    final kind = viewModel.kind;
    final name = await showCollectionNameDialog(context, kind: kind, accent: accent);
    if (name == null || !context.mounted) return;
    await viewModel.create.execute(name);
    if (!context.mounted) return;
    if (viewModel.create.error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't make the ${kind.name}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = GamePalette.of(context, viewModel.tcg).accent;
    final glass = context.glass;
    final kind = viewModel.kind;

    return ListenableBuilder(
      listenable: Listenable.merge([viewModel, searchViewModel]),
      builder: (context, _) {
        final collections = viewModel.collections;
        final searching = searchViewModel.search.value.trim().isNotEmpty;
        final found = searchViewModel.cards;

        return GlassScaffold(
          title: kind.label,
          game: viewModel.tcg,
          search: searchViewModel.search,
          searchHint: 'Search ${kind.name}s',
          actions: [
            IconButton(
              tooltip: 'New ${kind.name}',
              onPressed: () => _create(context, accent),
              icon: Icon(LucideIcons.plus, color: glass.textPrimary),
            ),
          ],
          children: [
            if (searching) ...[
              SectionHeading(
                'In your ${kind.name}s',
                trailing: searchViewModel.loading
                    ? null
                    : Text(
                        '${searchViewModel.total} ${searchViewModel.total == 1 ? 'card' : 'cards'}',
                        style: TextStyle(color: glass.textTertiary, fontSize: 13),
                      ),
              ),
              if (searchViewModel.loading)
                LoadingSection(color: accent)
              else if (found.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    searchViewModel.failed ? "Couldn't search your ${kind.name}s" : 'No cards in your ${kind.name}s match',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: glass.textSecondary),
                  ),
                )
              else ...[
                for (var i = 0; i < found.length; i += _columns)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ColumnGrid(
                      columns: _columns,
                      gap: 10,
                      children: [
                        for (final card in found.skip(i).take(_columns)) CatalogCardTile(card: card, accent: accent),
                      ],
                    ),
                  ),
                if (searchViewModel.loadingMore)
                  Center(child: LoadingIndicator(color: accent))
                else if (found.length < searchViewModel.total)
                  Center(
                    child: TextButton(
                      onPressed: searchViewModel.loadMore,
                      child: Text('Show more', style: TextStyle(color: accent, fontWeight: FontWeight.w600)),
                    ),
                  ),
              ],
            ] else if (collections == null)
              viewModel.load.running ? LoadingSection(color: accent) : _LoadFailed(kind: kind)
            else ...[
              ?header,
              for (final collection in collections)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CollectionCard(
                    collection: collection,
                    game: viewModel.tcg,
                    onTap: () => context.push(Routes.listFor(kind, collection.id)),
                  ),
                ),
              _NewCollectionButton(
                kind: kind,
                first: collections.isEmpty,
                accent: accent,
                onTap: () => _create(context, accent),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Makes a collection or wishlist; with some words on what they are when there are none yet.
class _NewCollectionButton extends StatelessWidget {
  final ListKind kind;
  final bool first;
  final Color accent;
  final VoidCallback onTap;

  const _NewCollectionButton({required this.kind, required this.first, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.plus, size: 18, color: accent),
              const SizedBox(width: 8),
              Text(
                first ? 'Make your first ${kind.name}' : 'New ${kind.name}',
                style: TextStyle(color: accent, fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (first) ...[
            const SizedBox(height: 8),
            Text(
              switch (kind) {
                ListKind.collection =>
                  'Sort your cards the way you keep them: a binder, a deck box, trades. A collection can hold cards of every game.',
                ListKind.wishlist =>
                  "Keep track of the cards you're after: for a deck, a set to finish, gifts. A wishlist can hold cards of every game.",
              },
              textAlign: TextAlign.center,
              style: TextStyle(color: glass.textSecondary, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

class _LoadFailed extends StatelessWidget {
  final ListKind kind;

  const _LoadFailed({required this.kind});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Text(
        "Couldn't load your ${kind.name}s",
        textAlign: TextAlign.center,
        style: TextStyle(color: context.glass.textSecondary),
      ),
    );
  }
}
