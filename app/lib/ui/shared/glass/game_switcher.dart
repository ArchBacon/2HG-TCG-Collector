// Copyright 2026 Christian Delicaat. All rights reserved.

import 'dart:ui';

import 'package:app/themes/game_palette.dart';
import 'package:app/themes/glass_theme.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/ui/shared/glass/card_thumb.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Header control for picking the game: the game's cardback icon + chevron (+ the name when not
/// [compact]). Opens a sheet with all games.
class GameSwitcherButton extends StatelessWidget {
  final Tcg? game;
  final ValueChanged<Tcg?> onChanged;
  final bool compact; // Icon + chevron only; screen readers still get the name

  const GameSwitcherButton({super.key, required this.game, required this.onChanged, this.compact = false});

  static const height = 38.0; // Shared by the other header controls
  static const _iconSize = 26.0; // Card icon height
  static const _inset = (height - _iconSize) / 2; // Gap around the card icon: 6

  /// Corner radius for the header controls (this switcher, the search field and the scan button):
  /// the card icon's corner plus the gap around it, so the switcher's corners run parallel to the
  /// card's.
  static const cornerRadius = _iconSize * 0.1 + _inset; // ~9
  static const _shape = BorderRadius.all(Radius.circular(cornerRadius));

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final name = game?.displayName ?? 'All games';

    return Semantics(
      button: true,
      label: 'Game: $name',
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: _shape,
          onTap: () async {
            final picked = await showGameSheet(context, current: game);
            if (picked != null) onChanged(picked.game);
          },
          child: Container(
            height: height,
            padding: EdgeInsets.fromLTRB(_inset, 0, compact ? 8 : 12, 0),
            decoration: BoxDecoration(
              color: glass.fill,
              borderRadius: _shape,
              border: Border.all(color: glass.edge),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GameIcon(game: game, size: _iconSize),
                if (!compact) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: glass.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                Icon(LucideIcons.chevronDown, size: 16, color: glass.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Result of the game sheet; wraps the game so "All games" (null) can be told apart from
/// "dismissed" (no result).
class GamePick {
  final Tcg? game;
  const GamePick(this.game);
}

/// Frosted bottom sheet listing "All games" and each game.
Future<GamePick?> showGameSheet(BuildContext context, {required Tcg? current}) {
  return showModalBottomSheet<GamePick>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x66000000),
    // Size to the content instead of the default cap of 9/16 of the screen (too short for all the
    // games); stays below the status bar
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _GameSheet(current: current),
  );
}

class _GameSheet extends StatelessWidget {
  final Tcg? current;

  const _GameSheet({required this.current});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    Widget option(Tcg? game) => ListTile(
      onTap: () => Navigator.pop(context, GamePick(game)),
      leading: GameIcon(game: game, size: 36),
      title: Text(
        game?.displayName ?? 'All games',
        style: TextStyle(color: glass.textPrimary, fontWeight: FontWeight.w600),
      ),
      trailing: game == current ? Icon(LucideIcons.check, color: GamePalette.of(context, game).accent) : null,
    );

    // Real blur here: the sheet sits over busy content
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            color: glass.bar,
            border: Border(top: BorderSide(color: glass.edge)),
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
                    decoration: BoxDecoration(color: glass.textTertiary, borderRadius: BorderRadius.circular(2)),
                  ),
                  option(null),
                  Divider(color: glass.divider, height: 1, indent: 16, endIndent: 16),
                  for (final game in Tcg.values) option(game),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Game icon: the cardback as a small card, [size] tall, or a grid icon for "All games" in the
/// same shape (so lists line up).
class GameIcon extends StatelessWidget {
  final Tcg? game;
  final double size;

  const GameIcon({super.key, required this.game, required this.size});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Container(
      width: size * CardThumb.aspect,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.1), // Card corners, scaled with the size
        color: GamePalette.of(context, game).colors.first.withValues(alpha: 0.3),
        border: Border.all(color: glass.edge),
        image: game == null ? null : DecorationImage(image: AssetImage(game!.imageAsset), fit: BoxFit.cover),
      ),
      child: game == null ? Icon(LucideIcons.layoutGrid, size: size * 0.45, color: glass.textPrimary) : null,
    );
  }
}
