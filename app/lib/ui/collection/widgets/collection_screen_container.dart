// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/collection/card_lists_repository.dart';
import 'package:app/data/repositories/collection/collection_repository.dart';
import 'package:app/data/repositories/wishlist/wishlist_repository.dart';
import 'package:app/domain/models/collection/list_kind.dart';
import 'package:app/themes/game_palette.dart';
import 'package:app/ui/catalog/view_models/catalog_viewmodel.dart';
import 'package:app/ui/collection/view_models/collection_viewmodel.dart';
import 'package:app/ui/collection/view_models/collections_viewmodel.dart';
import 'package:app/ui/collection/widgets/collection_screen.dart';
import 'package:app/ui/collection/widgets/collections_screen.dart';
import 'package:app/ui/shared/view_model_host.dart';
import 'package:app/ui/wishlist/view_models/wishlist_viewmodel.dart';
import 'package:app/ui/wishlist/widgets/new_in_store_card.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// The repository of the user's lists of [kind].
CardListsRepository _listsRepository(BuildContext context, ListKind kind) => switch (kind) {
  ListKind.collection => context.read<CollectionRepository>(),
  ListKind.wishlist => context.read<WishlistRepository>(),
};

/// Creates the [CollectionsViewModel] for the selected game's lists of [kind], and the
/// [CatalogViewModel] that searches the cards in them (new ones when the game changes). The
/// wishlists also get the wishlisted cards that just came into the store, above them.
class CollectionsScreenContainer extends StatelessWidget {
  final ListKind kind;

  const CollectionsScreenContainer({super.key, required this.kind});

  @override
  Widget build(BuildContext context) {
    return GameViewModelHost(
      create: (context, game) => CollectionsViewModel(tcg: game, listsRepository: _listsRepository(context, kind)),
      builder: (context, viewModel) => GameViewModelHost(
        create: (context, game) => CatalogViewModel(
          tcg: game,
          listKind: kind,
          listSearch: true,
          catalogRepository: context.read(),
          collectionRepository: context.read(),
          wishlistRepository: context.read(),
        ),
        builder: (context, searchViewModel) => switch (kind) {
          ListKind.collection => CollectionsScreen(viewModel: viewModel, searchViewModel: searchViewModel),
          ListKind.wishlist => GameViewModelHost(
            create: (context, game) => WishlistViewModel(tcg: game, wishlistRepository: context.read()),
            builder: (context, wishlistViewModel) => CollectionsScreen(
              viewModel: viewModel,
              searchViewModel: searchViewModel,
              header: _NewInStore(viewModel: wishlistViewModel),
            ),
          ),
        },
      ),
    );
  }
}

/// The wishlisted cards that just came into the store; nothing when there are none.
class _NewInStore extends StatelessWidget {
  final WishlistViewModel viewModel;

  const _NewInStore({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        if (viewModel.newInStore.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: NewInStoreCard(cards: viewModel.newInStore, accent: GamePalette.of(context, viewModel.tcg).accent),
        );
      },
    );
  }
}

/// Creates the [CollectionViewModel] for the collection or wishlist [collectionId] in the selected
/// game, and the [CatalogViewModel] of its cards (new ones when the game changes).
class CollectionScreenContainer extends StatelessWidget {
  final ListKind kind;
  final String collectionId;

  const CollectionScreenContainer({super.key, required this.kind, required this.collectionId});

  @override
  Widget build(BuildContext context) {
    return GameViewModelHost(
      create: (context, game) => CollectionViewModel(
        tcg: game,
        collectionId: collectionId,
        listsRepository: _listsRepository(context, kind),
      ),
      builder: (context, viewModel) => GameViewModelHost(
        create: (context, game) => CatalogViewModel(
          tcg: game,
          listId: collectionId,
          listKind: kind,
          catalogRepository: context.read(),
          collectionRepository: context.read(),
          wishlistRepository: context.read(),
        ),
        builder: (context, cardsViewModel) => CollectionScreen(viewModel: viewModel, cardsViewModel: cardsViewModel),
      ),
    );
  }
}
