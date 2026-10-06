// Copyright 2026 Christian Delicaat. All rights reserved.

// PROTOTYPE: screen frame and pieces shared by the prototype screens.

import 'package:app/routing/routes.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/ui/prototype/brand_icon.dart';
import 'package:app/ui/prototype/game_switcher.dart';
import 'package:app/ui/prototype/glass.dart';
import 'package:app/ui/prototype/proto_data.dart';
import 'package:app/ui/shared/glass_app_bar.dart';
import 'package:app/ui/shared/glass_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// Which backdrop the screens use; switchable in the prototype settings.
enum BackdropStyle { cards, mesh, artwork }

final protoBackdropStyle = ValueNotifier(BackdropStyle.cards);

// The backdrop for a game, following the setting above.
class ProtoBackdrop extends StatelessWidget {
  final Tcg? game;

  const ProtoBackdrop({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: protoBackdropStyle,
      builder: (context, style, _) => switch (style) {
        BackdropStyle.cards => CardsBackdrop(game: game),
        BackdropStyle.mesh => MeshBackdrop(game: game),
        BackdropStyle.artwork => ArtworkBackdrop(game: game),
      },
    );
  }
}

// Backdrop behind everything (including under the app bar and nav bar, whose real blur picks it
// up), and a scrolling column of content. Header in two rows, inside the same glass bar:
// 1. Brand icon (or a back button on pushed pages) and the page name on the left, the cart with
//    its item count on the right. Like Discogs.
// 2. The game switcher, on pages that are per game.
class ProtoScaffold extends StatelessWidget {
  final Widget? backdrop; // Null = follow the backdrop setting
  final Tcg? game;
  final ValueChanged<Tcg?>? onGameChanged; // Null = sets the shared game
  final String title; // Page name
  final bool showGameSwitcher; // False for pages that aren't per game (cart, settings)
  final List<Widget>? actions; // Extra header buttons, before the cart
  final bool showCart; // False on the cart page itself
  final List<Widget> children;
  final double sidePadding;

  const ProtoScaffold({
    super.key,
    this.backdrop,
    required this.game,
    this.onGameChanged,
    required this.title,
    this.showGameSwitcher = true,
    this.actions,
    this.showCart = true,
    required this.children,
    this.sidePadding = 16,
  });

  @override
  Widget build(BuildContext context) {
    // Pages pushed on top of a tab get the default back button instead of the brand icon
    final pushed = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;

    return Scaffold(
      backgroundColor: (ProtoTheme.isDark ? Colors.black : const Color(0xFFF4F6FA)),
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        leading: pushed ? null : const Padding(padding: EdgeInsets.only(left: 16), child: Center(child: BrandIcon(size: 32))),
        leadingWidth: pushed ? null : 56,
        titleSpacing: pushed ? null : 10,
        actions: [...?actions, if (showCart) const CartButton(), const SizedBox(width: 8)],
        title: Text(title, style: TextStyle(color: GlassText.primary, fontSize: 20, fontWeight: FontWeight.w700)),
        bottom: showGameSwitcher
            ? PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: GameSwitcherButton(game: game, onChanged: onGameChanged ?? (g) => protoGame.value = g),
                  ),
                ),
              )
            : null,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: backdrop ?? ProtoBackdrop(game: game)),
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

// Cart button for the header: the cart icon with the number of items on a small badge. Opens the
// cart as its own page.
class CartButton extends StatelessWidget {
  const CartButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: protoCart,
      builder: (context, lines, _) {
        final count = lines.fold(0, (n, l) => n + l.quantity);
        return IconButton(
          tooltip: 'Cart',
          onPressed: () => context.push(Routes.cart),
          icon: Badge(
            isLabelVisible: count > 0,
            label: Text('$count'),
            backgroundColor: ProtoTheme.isDark ? const Color(0xFF5CB85C) : const Color(0xFF2E8B3E),
            textColor: ProtoTheme.isDark ? const Color(0xFF0A0E12) : Colors.white,
            child: Icon(LucideIcons.shoppingCart, size: 22, color: GlassText.primary),
          ),
        );
      },
    );
  }
}

// Loads the wishlist and rebuilds on game changes; hands the screen the current game and its cards.
class ProtoWishlistBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, Tcg? game, List<ProtoCard> cards) builder;

  const ProtoWishlistBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: ProtoData.wishlist(),
      builder: (context, snapshot) {
        final all = snapshot.data ?? const <ProtoCard>[];
        return ValueListenableBuilder(
          valueListenable: protoGame,
          builder: (context, game, _) => builder(
            context,
            game,
            game == null ? all : all.where((c) => c.game == game).toList(),
          ),
        );
      },
    );
  }
}

// Big number with a small label under it.
class ProtoStat extends StatelessWidget {
  final String value;
  final String label;
  final Color? color; // Null = the regular text color

  const ProtoStat({super.key, required this.value, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color ?? GlassText.primary,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            height: 1.1,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: GlassText.secondary, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// Section heading placed directly on the backdrop.
class ProtoHeading extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const ProtoHeading(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: GlassText.primary, fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

// Thumbnail with the name over a dark fade, for the "new in store" rows.
class ProtoOverlayThumb extends StatelessWidget {
  final ProtoCard card;
  final double width;

  const ProtoOverlayThumb({super.key, required this.card, required this.width});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openCard(context, card),
      child: SizedBox(
      width: width,
      height: width / CardThumb.aspect,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(card.game.imageAsset, fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xE6000000), Color(0xB3000000), Color(0x00000000)],
                  stops: [0, 0.3, 0.75],
                ),
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: GlassText.onImage, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    card.number,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: GlassText.onImageSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            // Thin glass edge, so the card reads as an object on the backdrop
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0x24FFFFFF)),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// Groups cards by set, keeping the order they first appear in.
Map<String, List<ProtoCard>> groupBySet(List<ProtoCard> cards) {
  final groups = <String, List<ProtoCard>>{};
  for (final card in cards) {
    groups.putIfAbsent(card.setName, () => []).add(card);
  }
  return groups;
}

// Opens the card details page (full screen, over the nav bar).
void openCard(BuildContext context, ProtoCard card) => context.push(Routes.cardFor(card.id));

// Compact game tile for the "All games" overviews: the game's color glowing in the corner, its
// cardback peeking in, name and two small stats.
class ProtoGameTile extends StatelessWidget {
  final Tcg game;
  final List<(IconData icon, String label)> stats;
  final int newCount; // Shows a "N new" chip when above 0
  final VoidCallback onTap;

  const ProtoGameTile({super.key, required this.game, required this.stats, this.newCount = 0, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = GamePalette.of(game);

    return GlassCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: SizedBox(
        height: 150,
        child: Stack(
          children: [
            // The game's color glowing from the top-right
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(1, -1),
                    radius: 1.2,
                    colors: [palette.glows.first.withValues(alpha: 0.35), palette.glows.first.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
            // Cardback peeking in from the top-right, tilted
            Positioned(
              top: -14,
              right: -12,
              child: Transform.rotate(
                angle: 0.25,
                child: Opacity(opacity: 0.9, child: CardThumb(game: game, width: 58, radius: 6)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (newCount > 0) GlassChip(label: '$newCount new', color: palette.accent, filled: true),
                  const Spacer(),
                  Text(
                    game.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: GlassText.primary, fontSize: 15, fontWeight: FontWeight.w700, height: 1.2),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      for (final (i, (icon, label)) in stats.indexed) ...[
                        if (i > 0) const SizedBox(width: 12),
                        Icon(icon, size: 12, color: GlassText.tertiary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: GlassText.secondary, fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Lays out tiles in a fixed number of equal-width columns.
class ProtoGrid extends StatelessWidget {
  final int columns;
  final double gap;
  final double runGap;
  final List<Widget> children;

  const ProtoGrid({super.key, required this.columns, this.gap = 12, this.runGap = 12, required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: runGap,
          children: [for (final child in children) SizedBox(width: width, child: child)],
        );
      },
    );
  }
}

// Glass card holding rows, with thin dividers between them.
class ProtoListCard extends StatelessWidget {
  final List<Widget> rows;
  final double dividerIndent;

  const ProtoListCard({super.key, required this.rows, this.dividerIndent = 16});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, row) in rows.indexed) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: GlassColors.current.divider, indent: dividerIndent),
            row,
          ],
        ],
      ),
    );
  }
}
