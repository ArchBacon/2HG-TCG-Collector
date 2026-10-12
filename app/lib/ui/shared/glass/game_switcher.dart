// Copyright 2026 Christian Delicaat. All rights reserved.

import 'dart:ui';

import 'package:app/themes/game_palette.dart';
import 'package:app/themes/glass_theme.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/ui/shared/glass/card_thumb.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Header control for switching game: the game's cardback icon + chevron (screen readers get the
/// name). Opens a sheet with the games. To see all games, the brand icon goes to the start screen.
class GameSwitcherButton extends StatelessWidget {
  final Tcg game;
  final ValueChanged<Tcg> onChanged;

  const GameSwitcherButton({super.key, required this.game, required this.onChanged});

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

    return Semantics(
      button: true,
      label: 'Game: ${game.displayName}',
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: _shape,
          onTap: () async {
            final picked = await showGameSheet(context, current: game);
            if (picked != null) onChanged(picked);
          },
          child: Container(
            height: height,
            padding: const EdgeInsets.fromLTRB(_inset, 0, 8, 0),
            decoration: BoxDecoration(
              color: glass.fill,
              borderRadius: _shape,
              border: Border.all(color: glass.edge),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GameIcon(game: game, size: _iconSize),
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

/// Frosted bottom sheet listing the games. Returns the picked one, or null when dismissed.
Future<Tcg?> showGameSheet(BuildContext context, {required Tcg current}) {
  return showModalBottomSheet<Tcg>(
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
  final Tcg current;

  const _GameSheet({required this.current});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    Widget option(Tcg game) => ListTile(
      onTap: () => Navigator.pop(context, game),
      leading: GameIcon(game: game, size: 36),
      title: Text(
        game.displayName,
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

/// Game icon: the game's cardback as a small card, [size] tall.
class GameIcon extends StatelessWidget {
  final Tcg game;
  final double size;

  const GameIcon({super.key, required this.game, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * CardThumb.aspect,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.1), // Card corners, scaled with the size
        border: Border.all(color: context.glass.edge),
        image: DecorationImage(image: AssetImage(game.imageAsset), fit: BoxFit.cover),
      ),
    );
  }
}
