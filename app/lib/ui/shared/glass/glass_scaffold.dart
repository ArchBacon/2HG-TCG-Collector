// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/themes/game_palette.dart';
import 'package:app/themes/glass_theme.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/ui/shared/app_state.dart';
import 'package:app/ui/shared/glass/brand_icon.dart';
import 'package:app/ui/shared/glass/game_backdrop.dart';
import 'package:app/ui/shared/glass/game_switcher.dart';
import 'package:app/ui/shared/glass/header_controls.dart';
import 'package:app/ui/shared/glass_app_bar.dart';
import 'package:app/ui/shared/glass_nav_bar.dart';
import 'package:flutter/material.dart';

/// Page frame for the screens: the game's background behind everything (including under the app
/// bar and nav bar, whose real blur picks it up), a two-row glass header, and a scrolling column
/// of content.
///
/// Header:
/// 1. Brand icon (or a back button on pushed pages) and the page name on the left, the cart with
///    its item count on the right.
/// 2. On pages that are per game: the game switcher, and with a game picked, search and scan.
class GlassScaffold extends StatelessWidget {
  final Tcg? game;
  final String title; // Page name
  final bool showGameSwitcher; // False for pages that aren't per game, or that pick the game themselves
  final bool showCart; // False on the cart page itself
  final List<Widget> children;
  final double sidePadding;

  const GlassScaffold({
    super.key,
    required this.game,
    required this.title,
    this.showGameSwitcher = true,
    this.showCart = true,
    required this.children,
    this.sidePadding = 16,
  });

  @override
  Widget build(BuildContext context) {
    // Pages pushed on top of a tab get the default back button instead of the brand icon
    final pushed = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;

    return Scaffold(
      backgroundColor: GamePalette.of(context, game).base,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        leading: pushed ? null : const Padding(padding: EdgeInsets.only(left: 16), child: Center(child: BrandIcon(size: 32))),
        leadingWidth: pushed ? null : 56,
        titleSpacing: pushed ? null : 10,
        actions: [if (showCart) const CartButton(), const SizedBox(width: 8)],
        title: Text(title, style: TextStyle(color: context.glass.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
        bottom: showGameSwitcher ? _GameRow(game: game) : null,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: GameBackdrop(game: game)),
          // Builder: the paddings must be read inside the Scaffold body, where its MediaQuery
          // includes the app bar height. This widget's own context is outside the Scaffold.
          Builder(
            builder: (context) => ListView(
              padding: EdgeInsets.fromLTRB(
                sidePadding,
                GlassAppBar.contentTopPadding(context) + 16,
                sidePadding,
                GlassNavBar.contentBottomPadding(context) + 24,
              ),
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

/// Second header row: compact game switcher, then search and scan (only with a game picked: they
/// work within one game).
class _GameRow extends StatelessWidget implements PreferredSizeWidget {
  final Tcg? game;

  const _GameRow({required this.game});

  @override
  Size get preferredSize => const Size.fromHeight(GameSwitcherButton.height + 10);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          GameSwitcherButton(
            game: game,
            compact: game != null,
            onChanged: (game) => selectedGame.value = game,
          ),
          if (game != null) ...[
            const SizedBox(width: 8),
            Expanded(child: HeaderSearchField(game: game!)),
            const SizedBox(width: 8),
            const ScanButton(),
          ],
        ],
      ),
    );
  }
}
