// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/routing/routes.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/ui/shared/collection_value.dart';
import 'package:app/ui/home/widgets/tcg_game_list.dart';
import 'package:app/ui/shared/glass_app_bar.dart';
import 'package:app/ui/shared/glass_nav_bar.dart';
import 'package:app/ui/home/view_models/home_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.viewModel,
  });

  final HomeViewModel viewModel;

  @override
  State<StatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(title: Text('TCG Collector')),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, child) {
          final summary = widget.viewModel.summary;

          return ListView(
            padding: EdgeInsets.fromLTRB(12, GlassAppBar.contentTopPadding(context) + 12, 12, GlassNavBar.contentBottomPadding(context) + 12),
            children: [
              // Collection Summary
              CollectionSummaryCard(
                  value: summary?.total.value ?? 0,
                  collected: summary?.total.collected ?? 0,
                  wishlisted: summary?.total.wishlisted ?? 0
              ),
              const SizedBox(height: 12),
              TcgGameList(
                games: (summary?.tcgs.entries.map((entry) => WishlistGameSummary(
                    game: Tcg.values.firstWhere((t) => t.slug == entry.key),
                    latestSet: entry.value.latestSet?.name ?? '',
                    value: entry.value.value,
                    cardCount: entry.value.collected
                )).toList() ?? [])
                // sort tcgs by high to low collected cards
                ..sort((a, b) => b.cardCount.compareTo(a.cardCount)),
                onSelected: (tcg) => context.push(Routes.overviewFor(tcg)),
              ),
            ],
          );
        }
      ),
    );
  }
}