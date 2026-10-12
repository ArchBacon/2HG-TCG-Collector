// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/ui/collection/view_models/collection_viewmodel.dart';
import 'package:app/ui/collection/widgets/collection_screen.dart';
import 'package:app/ui/shared/view_model_host.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// Creates the [CollectionViewModel] for the selected game (and a new one when it changes).
class CollectionScreenContainer extends StatelessWidget {
  const CollectionScreenContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return GameViewModelHost(
      create: (context, game) => CollectionViewModel(tcg: game, collectionRepository: context.read()),
      builder: (context, viewModel) => CollectionScreen(viewModel: viewModel),
    );
  }
}
