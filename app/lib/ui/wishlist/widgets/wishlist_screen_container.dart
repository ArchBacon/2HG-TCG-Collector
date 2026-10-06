// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/collection/collection_repository.dart';
import 'package:app/ui/wishlist/view_models/wishlist_viewmodel.dart';
import 'package:app/ui/wishlist/widgets/wishlist_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// Creates the [WishlistViewModel] once for the lifetime of the page, and disposes it when the page is removed.
class WishlistScreenContainer extends StatefulWidget {
  const WishlistScreenContainer({super.key});

  @override
  State<WishlistScreenContainer> createState() => _WishlistScreenContainerState();
}

class _WishlistScreenContainerState extends State<WishlistScreenContainer> {
  late final WishlistViewModel _viewModel;

  @override
  void initState() {
    super.initState();

    _viewModel = WishlistViewModel(
      collectionRepository: context.read<CollectionRepository>(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WishlistScreen(viewModel: _viewModel);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }
}
