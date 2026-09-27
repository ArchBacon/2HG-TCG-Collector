// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/collection/collection_repository.dart';
import 'package:app/ui/home/view_models/home_viewmodel.dart';
import 'package:app/ui/home/widgets/home_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// Creates the [HomeViewModel] once for the lifetime of the page, and disposes it when the page is removed.
class HomeScreenContainer extends StatefulWidget {
  const HomeScreenContainer({super.key});

  @override
  State<HomeScreenContainer> createState() => _HomeScreenContainerState();
}

class _HomeScreenContainerState extends State<HomeScreenContainer> {
  late final HomeViewModel _viewModel;

  @override
  void initState() {
    super.initState();

    _viewModel = HomeViewModel(
      collectionRepository: context.read<CollectionRepository>(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HomeScreen(viewModel: _viewModel);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }
}
