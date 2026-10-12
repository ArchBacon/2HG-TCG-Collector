// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/routing/routes.dart';
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
import 'package:go_router/go_router.dart';

/// Page frame for the screens: the game's background behind everything (including under the app
/// bar and nav bar, whose real blur picks it up), a two-row glass header, and a scrolling column
/// of content.
///
/// Header:
/// 1. Brand icon (back to the start screen; a back button on pushed pages) and the page name on
///    the left, extra buttons and the cart with its item count on the right.
/// 2. On a game's pages: the game switcher, search and scan.
class GlassScaffold extends StatelessWidget {
  final Tcg? game;
  final String title; // Page name
  final bool showGameSwitcher; // False for pages that aren't per game
  final bool showCart; // False on the cart page itself
  final bool isStartScreen; // The brand icon doesn't link to the start screen on the start screen itself
  final List<Widget>? actions; // Extra header buttons, before the cart
  final List<Widget> children;
  final double sidePadding;

  const GlassScaffold({
    super.key,
    required this.game,
    required this.title,
    this.showGameSwitcher = true,
    this.showCart = true,
    this.isStartScreen = false,
    this.actions,
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
        leading: pushed ? null : _BrandButton(linksToStart: !isStartScreen),
        leadingWidth: pushed ? null : 56,
        titleSpacing: pushed ? null : 10,
        actions: [...?actions, if (showCart) const CartButton(), const SizedBox(width: 8)],
        title: Text(title, style: TextStyle(color: context.glass.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
        bottom: showGameSwitcher && game != null ? _GameRow(game: game!) : null,
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

/// The brand icon at the start of the header. On a game's pages it goes back to the start screen,
/// to see all games or pick another.
class _BrandButton extends StatelessWidget {
  final bool linksToStart;

  const _BrandButton({required this.linksToStart});

  @override
  Widget build(BuildContext context) {
    const icon = Center(child: BrandIcon(size: 32));

    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: linksToStart
          ? Tooltip(
              message: 'All games',
              child: InkResponse(radius: 22, onTap: () => context.go(Routes.start), child: icon),
            )
          : icon,
    );
  }
}

/// Second header row: compact game switcher, search and scan.
class _GameRow extends StatelessWidget implements PreferredSizeWidget {
  final Tcg game;

  const _GameRow({required this.game});

  @override
  Size get preferredSize => const Size.fromHeight(GameSwitcherButton.height + 10);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          GameSwitcherButton(game: game, onChanged: (game) => selectedGame.value = game),
          const SizedBox(width: 8),
          Expanded(child: HeaderSearchField(game: game)),
          const SizedBox(width: 8),
          const ScanButton(),
        ],
      ),
    );
  }
}
