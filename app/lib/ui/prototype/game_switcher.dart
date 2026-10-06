// Copyright 2026 Christian Delicaat. All rights reserved.

// PROTOTYPE: the game as global context instead of a navigation step. The current game lives in
// one place, every screen follows it, and it's changed from a pill in the app bar.

import 'dart:ui';

import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/ui/prototype/glass.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// The current game, shared by all prototype screens. Null = all games.
final protoGame = ValueNotifier<Tcg?>(Tcg.pokemon);

// App bar title: game icon + name + chevron. Opens the game sheet.
class GameSwitcherButton extends StatelessWidget {
  final Tcg? game;
  final ValueChanged<Tcg?> onChanged;

  const GameSwitcherButton({super.key, required this.game, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () async {
          final picked = await showGameSheet(context, current: game);
          if (picked != null) onChanged(picked.game);
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 5, 12, 5),
          decoration: BoxDecoration(
            color: GlassColors.of(context).fill,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: GlassColors.current.edge),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _GameIcon(game: game, size: 24),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  game?.displayName ?? 'All games',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: GlassText.primary, fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 4),
              Icon(LucideIcons.chevronDown, size: 16, color: GlassText.secondary),
            ],
          ),
        ),
      ),
    );
  }
}

// Wrapper so "All games" (null) can be told apart from "dismissed" (no result).
class GamePick {
  final Tcg? game;
  const GamePick(this.game);
}

// Frosted bottom sheet listing "All games" and each game.
Future<GamePick?> showGameSheet(BuildContext context, {required Tcg? current}) {
  return showModalBottomSheet<GamePick>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x66000000),
    // Size to the content instead of the default cap of 9/16 of the screen (too short for all the
    // games); stays below the status bar
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) {
      Widget option(Tcg? game) {
        final selected = game == current;
        return ListTile(
          onTap: () => Navigator.pop(context, GamePick(game)),
          leading: _GameIcon(game: game, size: 36),
          title: Text(
            game?.displayName ?? 'All games',
            style: TextStyle(color: GlassText.primary, fontWeight: FontWeight.w600),
          ),
          trailing: selected ? Icon(LucideIcons.check, color: GamePalette.of(game).accent) : null,
        );
      }

      // Real blur here: the sheet sits over busy content.
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              color: GlassColors.current.bar,
              border: Border(top: BorderSide(color: GlassColors.current.edge)),
            ),
            child: SafeArea(
              top: false,
              // Scrolls if the screen is too short to show everything (e.g. landscape)
              child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(color: GlassText.tertiary, borderRadius: BorderRadius.circular(2)),
                  ),
                  option(null),
                  Divider(color: GlassColors.current.divider, height: 1, indent: 16, endIndent: 16),
                  for (final game in Tcg.values) option(game),
                  const SizedBox(height: 8),
                ],
              ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

// Round game icon: a crop of the cardback, or a grid icon for "All games".
class _GameIcon extends StatelessWidget {
  final Tcg? game;
  final double size;

  const _GameIcon({required this.game, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: GamePalette.of(game).glows.first.withValues(alpha: 0.3),
        border: Border.all(color: GlassColors.current.edge),
        image: game == null
            ? null
            : DecorationImage(image: AssetImage(game!.imageAsset), fit: BoxFit.cover),
      ),
      child: game == null ? Icon(LucideIcons.layoutGrid, size: size * 0.5, color: GlassText.primary) : null,
    );
  }
}
