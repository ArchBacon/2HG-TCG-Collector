// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/collection/collection_repository.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/ui/overview/view_models/overview_viewmodel.dart';
import 'package:app/ui/overview/widgets/overview_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// Creates the [OverviewViewModel] once for the lifetime of the page, and disposes it when the page is removed.
class OverviewScreenContainer extends StatefulWidget {
  const OverviewScreenContainer({super.key, required this.tcg});

  final Tcg tcg;

  @override
  State<OverviewScreenContainer> createState() => _OverviewScreenContainerState();
}

class _OverviewScreenContainerState extends State<OverviewScreenContainer> {
  late final OverviewViewModel _viewModel;

  @override
  void initState() {
    super.initState();

    _viewModel = OverviewViewModel(
      tcg: widget.tcg,
      collectionRepository: context.read<CollectionRepository>(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OverviewScreen(viewModel: _viewModel);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }
}
