// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/ui/overview/widgets/set_blocks_list.dart';
import 'package:app/ui/shared/collection_value.dart';
import 'package:app/ui/shared/glass_app_bar.dart';
import 'package:app/ui/shared/glass_nav_bar.dart';
import 'package:app/ui/overview/view_models/overview_viewmodel.dart';
import 'package:app/ui/shared/searchbar.dart';
import 'package:flutter/material.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({
    super.key,
    required this.viewModel,
  });

  final OverviewViewModel viewModel;

  @override
  State<StatefulWidget> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant OverviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tcg = widget.viewModel.tcg;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(title: Text(tcg.displayName)),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, child) {
          final overview = widget.viewModel.overview;
          return ListView(
            padding: EdgeInsets.fromLTRB(12, GlassAppBar.contentTopPadding(context) + 12, 12, GlassNavBar.contentBottomPadding(context) + 12),
            children: [

              // Collection Summary
              CollectionSummaryCard(
                  value: overview?.summary.value ?? 0,
                  collected: overview?.summary.collected ?? 0,
                  wishlisted: overview?.summary.wishlisted ?? 0
              ),
              const SizedBox(height: 12),
              // Search input
              AppSearchBar(
                hint: 'Search cards...',
              ),
              const SizedBox(height: 12),
              SetBlockList(tcg: tcg, blocks: overview?.blocks ?? []),
            ],
          );
        }
      ),
    );
  }
}