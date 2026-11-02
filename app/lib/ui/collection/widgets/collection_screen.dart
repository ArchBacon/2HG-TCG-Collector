// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/themes/game_palette.dart';
import 'package:app/themes/glass_theme.dart';
import 'package:app/ui/catalog/view_models/catalog_viewmodel.dart';
import 'package:app/ui/catalog/widgets/catalog_screen.dart';
import 'package:app/ui/collection/view_models/collection_viewmodel.dart';
import 'package:app/ui/collection/widgets/collection_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// One collection or wishlist, for the selected game: its cards like the catalog shows them, with the
/// same filters, sorting and layouts. Renamed and deleted from the menu in the header.
class CollectionScreen extends StatelessWidget {
  final CollectionViewModel viewModel;
  final CatalogViewModel cardsViewModel; // The list's cards

  const CollectionScreen({super.key, required this.viewModel, required this.cardsViewModel});

  Future<void> _rename(BuildContext context, Color accent) async {
    final kind = viewModel.kind;
    final name = await showCollectionNameDialog(
      context,
      kind: kind,
      accent: accent,
      initial: viewModel.collection?.name ?? '',
    );
    if (name == null || !context.mounted) return;
    await viewModel.rename.execute(name);
    if (context.mounted && viewModel.rename.error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't rename the ${kind.name}")));
    }
  }

  Future<void> _delete(BuildContext context) async {
    final kind = viewModel.kind;
    final name = viewModel.collection?.name ?? '';
    if (!await confirmDeleteCollection(context, kind: kind, name: name) || !context.mounted) return;
    await viewModel.delete.execute();
    if (!context.mounted) return;
    if (viewModel.delete.error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't delete the ${kind.name}")));
      return;
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final accent = GamePalette.of(context, viewModel.tcg).accent;
    final glass = context.glass;

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final collection = viewModel.collection;

        return CatalogScreen(
          viewModel: cardsViewModel,
          title: collection?.name ?? viewModel.kind.label,
          trailingActions: [
            if (collection != null)
              PopupMenuButton<_Action>(
                tooltip: '${viewModel.kind.label} options',
                icon: Icon(LucideIcons.ellipsisVertical, color: glass.textPrimary),
                color: glass.sheet,
                onSelected: (action) => switch (action) {
                  _Action.rename => _rename(context, accent),
                  _Action.delete => _delete(context),
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: _Action.rename, child: Text('Rename', style: TextStyle(color: glass.textPrimary))),
                  PopupMenuItem(
                    value: _Action.delete,
                    child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}

enum _Action { rename, delete }
