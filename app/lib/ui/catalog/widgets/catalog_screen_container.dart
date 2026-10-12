// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/ui/catalog/view_models/catalog_viewmodel.dart';
import 'package:app/ui/catalog/widgets/catalog_screen.dart';
import 'package:app/ui/shared/view_model_host.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// Creates the [CatalogViewModel] for the selected game (and a new one when it changes, which also
/// resets the filters).
class CatalogScreenContainer extends StatelessWidget {
  const CatalogScreenContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return GameViewModelHost(
      create: (context, game) => CatalogViewModel(tcg: game, catalogRepository: context.read()),
      builder: (context, viewModel) => CatalogScreen(viewModel: viewModel),
    );
  }
}
