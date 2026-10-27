// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/ui/catalog/view_models/catalog_viewmodel.dart';
import 'package:app/ui/collection/view_models/collection_viewmodel.dart';
import 'package:app/ui/collection/view_models/collections_viewmodel.dart';
import 'package:app/ui/collection/widgets/collection_screen.dart';
import 'package:app/ui/collection/widgets/collections_screen.dart';
import 'package:app/ui/shared/view_model_host.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// Creates the [CollectionsViewModel] for the selected game, and the [CatalogViewModel] that
/// searches the cards in the collections (new ones when the game changes).
class CollectionsScreenContainer extends StatelessWidget {
  const CollectionsScreenContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return GameViewModelHost(
      create: (context, game) => CollectionsViewModel(tcg: game, collectionRepository: context.read()),
      builder: (context, viewModel) => GameViewModelHost(
        create: (context, game) => CatalogViewModel(
          tcg: game,
          ownedOnly: true,
          catalogRepository: context.read(),
          collectionRepository: context.read(),
        ),
        builder: (context, searchViewModel) =>
            CollectionsScreen(viewModel: viewModel, searchViewModel: searchViewModel),
      ),
    );
  }
}

/// Creates the [CollectionViewModel] for collection [collectionId] in the selected game, and the
/// [CatalogViewModel] of its cards (new ones when the game changes).
class CollectionScreenContainer extends StatelessWidget {
  final String collectionId;

  const CollectionScreenContainer({super.key, required this.collectionId});

  @override
  Widget build(BuildContext context) {
    return GameViewModelHost(
      create: (context, game) =>
          CollectionViewModel(tcg: game, collectionId: collectionId, collectionRepository: context.read()),
      builder: (context, viewModel) => GameViewModelHost(
        create: (context, game) => CatalogViewModel(
          tcg: game,
          collectionId: collectionId,
          catalogRepository: context.read(),
          collectionRepository: context.read(),
        ),
        builder: (context, cardsViewModel) => CollectionScreen(viewModel: viewModel, cardsViewModel: cardsViewModel),
      ),
    );
  }
}
