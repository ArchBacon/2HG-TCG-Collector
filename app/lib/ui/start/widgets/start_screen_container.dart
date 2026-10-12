// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/ui/shared/view_model_host.dart';
import 'package:app/ui/start/view_models/start_viewmodel.dart';
import 'package:app/ui/start/widgets/start_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// Creates the [StartViewModel] for the start screen.
class StartScreenContainer extends StatelessWidget {
  const StartScreenContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelHost(
      create: (context) => StartViewModel(collectionRepository: context.read(), wishlistRepository: context.read()),
      builder: (context, viewModel) => StartScreen(viewModel: viewModel),
    );
  }
}
