// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/services/mock/mock_cart.dart';
import 'package:app/routing/navigation.dart';
import 'package:app/routing/routes.dart';
import 'package:app/themes/game_palette.dart';
import 'package:app/themes/glass_theme.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/ui/shared/app_state.dart';
import 'package:app/ui/shared/glass/game_switcher.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Search field in the header, for the selected game's catalog. The text is shared by every tab
/// ([cardSearch]): the Catalog filters on it as you type; on other tabs, submitting opens the
/// Catalog.
class HeaderSearchField extends StatefulWidget {
  final Tcg game;

  const HeaderSearchField({super.key, required this.game});

  @override
  State<HeaderSearchField> createState() => _HeaderSearchFieldState();
}

class _HeaderSearchFieldState extends State<HeaderSearchField> {
  // Starts with the shared text, and follows it: every tab has its own header, and they should all
  // show the same search
  late final _controller = TextEditingController(text: cardSearch.value);

  @override
  void initState() {
    super.initState();
    cardSearch.addListener(_sync);
  }

  @override
  void dispose() {
    cardSearch.removeListener(_sync);
    _controller.dispose();
    super.dispose();
  }

  void _sync() {
    if (_controller.text != cardSearch.value) setState(() => _controller.text = cardSearch.value);
  }

  void _openCatalog() {
    if (GoRouterState.of(context).matchedLocation != Routes.catalog) context.go(Routes.catalog);
  }

  void _clear() {
    _controller.clear();
    cardSearch.value = '';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final accent = GamePalette.of(context, widget.game).accent;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(GameSwitcherButton.cornerRadius),
      borderSide: BorderSide(color: glass.edge),
    );

    return TextField(
      controller: _controller,
      onChanged: (text) {
        cardSearch.value = text;
        setState(() {}); // Show/hide the clear button
      },
      onSubmitted: (_) => _openCatalog(),
      textInputAction: TextInputAction.search,
      // Single line: long searches scroll instead of wrapping
      maxLines: 1,
      textAlignVertical: TextAlignVertical.center,
      style: TextStyle(color: glass.textPrimary, fontSize: 14),
      cursorColor: accent,
      decoration: InputDecoration(
        hintText: 'Search cards', // The game icon right next to it says which game
        hintStyle: TextStyle(color: glass.textTertiary, fontSize: 14),
        hintMaxLines: 1,
        // Exactly as tall as the other header controls; a text field otherwise sizes itself to its
        // text and padding
        constraints: const BoxConstraints.tightFor(height: GameSwitcherButton.height),
        prefixIcon: Icon(LucideIcons.search, size: 16, color: glass.textSecondary),
        prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: GameSwitcherButton.height),
        suffixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: GameSwitcherButton.height),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear',
                // Fits inside the field (the default button is 48px)
                constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                padding: EdgeInsets.zero,
                icon: Icon(LucideIcons.x, size: 16, color: glass.textSecondary),
                onPressed: _clear,
              ),
        filled: true,
        fillColor: glass.fill,
        isDense: true,
        contentPadding: EdgeInsets.zero,
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(borderSide: BorderSide(color: accent.withValues(alpha: 0.6))),
      ),
    );
  }
}

/// Square glass button for scanning a card with the camera (not built yet).
class ScanButton extends StatelessWidget {
  const ScanButton({super.key});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final radius = BorderRadius.circular(GameSwitcherButton.cornerRadius);

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: radius,
        onTap: () => ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Scanning isn\'t built yet'))),
        child: Ink(
          width: GameSwitcherButton.height,
          height: GameSwitcherButton.height,
          decoration: BoxDecoration(color: glass.fill, borderRadius: radius, border: Border.all(color: glass.edge)),
          child: Tooltip(
            message: 'Scan a card',
            child: Icon(LucideIcons.scanLine, size: 18, color: glass.textPrimary),
          ),
        ),
      ),
    );
  }
}

/// Cart button for the header: the cart icon with the number of items on a small badge. Opens the
/// cart as its own page.
class CartButton extends StatelessWidget {
  const CartButton({super.key});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return ValueListenableBuilder(
      valueListenable: cart,
      builder: (context, lines, _) {
        final count = lines.fold(0, (n, l) => n + l.quantity);
        return IconButton(
          tooltip: 'Cart',
          onPressed: context.openCart,
          icon: Badge(
            isLabelVisible: count > 0,
            label: Text('$count'),
            backgroundColor: glass.badge,
            textColor: glass.onBadge,
            child: Icon(LucideIcons.shoppingCart, size: 22, color: glass.textPrimary),
          ),
        );
      },
    );
  }
}
