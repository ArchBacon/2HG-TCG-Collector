// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/ui/shared/view_model_host.dart';
import 'package:app/ui/wishlist/view_models/wishlist_viewmodel.dart';
import 'package:app/ui/wishlist/widgets/wishlist_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// Creates the [WishlistViewModel] for the selected game (and a new one when it changes).
class WishlistScreenContainer extends StatelessWidget {
  const WishlistScreenContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return GameViewModelHost(
      create: (context, game) => WishlistViewModel(tcg: game, wishlistRepository: context.read()),
      builder: (context, viewModel) => WishlistScreen(viewModel: viewModel),
    );
  }
}
