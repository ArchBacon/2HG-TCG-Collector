// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/cart/cart_repository.dart';
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
import 'package:provider/provider.dart';

/// Search field in the header. By default for the selected game's catalog: that text is shared by
/// every tab ([cardSearch]), the Catalog filters on it as you type, and on other tabs submitting
/// opens the Catalog. A page that searches its own cards (a collection, the wishlist) gives its own
/// [query] and [hint] instead.
///
/// Typing anywhere but the Catalog shows a shortcut under the field, to search the catalog for it
/// instead.
class HeaderSearchField extends StatefulWidget {
  final Tcg game;
  final ValueNotifier<String>? query; // Null = the catalog's search
  final String? hint; // Null = "Search catalog"

  const HeaderSearchField({super.key, required this.game, this.query, this.hint});

  @override
  State<HeaderSearchField> createState() => _HeaderSearchFieldState();
}

class _HeaderSearchFieldState extends State<HeaderSearchField> {
  // Starts with the query's text, and follows it: every tab has its own header, and the catalog's
  // search shows the same on all of them
  late final ValueNotifier<String> _query = widget.query ?? cardSearch;
  late final _controller = TextEditingController(text: _query.value);

  final _focus = FocusNode();
  final _shortcut = OverlayPortalController(); // "Search catalog for ..." under the field
  final _link = LayerLink();
  double _width = 0; // The field's, for the shortcut

  bool get _searchesCatalog => widget.query == null;

  bool get _onCatalog => GoRouterState.of(context).matchedLocation == Routes.catalog;

  @override
  void initState() {
    super.initState();
    _query.addListener(_sync);
    _focus.addListener(_updateShortcut);
    _controller.addListener(_updateShortcut); // However the text changes: typed, cleared, or synced
  }

  @override
  void dispose() {
    _query.removeListener(_sync);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _sync() {
    if (_controller.text != _query.value) setState(() => _controller.text = _query.value);
  }

  void _updateShortcut() {
    final show = _focus.hasFocus && _controller.text.trim().isNotEmpty && !_onCatalog;
    if (show != _shortcut.isShowing) show ? _shortcut.show() : _shortcut.hide();
  }

  /// Searches the catalog for what's typed here, and opens it.
  void _searchCatalog() {
    cardSearch.value = _controller.text.trim();
    _focus.unfocus();
    _shortcut.hide();
    context.go(Routes.catalog);
  }

  void _openCatalog() {
    if (GoRouterState.of(context).matchedLocation != Routes.catalog) context.go(Routes.catalog);
  }

  void _clear() {
    _controller.clear();
    _query.value = '';
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

    final field = TextField(
      controller: _controller,
      focusNode: _focus,
      onChanged: (text) {
        _query.value = text;
        setState(() {}); // Show/hide the clear button
      },
      onSubmitted: (_) => _searchesCatalog ? _openCatalog() : null,
      textInputAction: TextInputAction.search,
      // Single line: long searches scroll instead of wrapping
      maxLines: 1,
      textAlignVertical: TextAlignVertical.center,
      style: TextStyle(color: glass.textPrimary, fontSize: 14),
      cursorColor: accent,
      decoration: InputDecoration(
        hintText: widget.hint ?? 'Search catalog', // The game icon right next to it says which game
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

    return OverlayPortal(
      controller: _shortcut,
      overlayChildBuilder: (context) => CompositedTransformFollower(
        link: _link,
        targetAnchor: Alignment.bottomLeft,
        offset: const Offset(0, 6),
        child: Align(
          alignment: Alignment.topLeft,
          // Part of the field for taps: tapping it doesn't count as tapping away from the field
          child: TextFieldTapRegion(
            child: SizedBox(
              width: _width,
              child: _CatalogShortcut(text: _controller.text.trim(), accent: accent, onTap: _searchCatalog),
            ),
          ),
        ),
      ),
      child: CompositedTransformTarget(
        link: _link,
        child: LayoutBuilder(
          builder: (context, constraints) {
            _width = constraints.maxWidth;
            return field;
          },
        ),
      ),
    );
  }
}

/// "Search catalog for ..." with the typed text, under the header's search field on pages other than the Catalog.
class _CatalogShortcut extends StatelessWidget {
  final String text;
  final Color accent;
  final VoidCallback onTap;

  const _CatalogShortcut({required this.text, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Material(
      color: glass.sheet,
      elevation: 8,
      borderRadius: BorderRadius.circular(GameSwitcherButton.cornerRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(LucideIcons.library, size: 16, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Search catalog for '),
                      TextSpan(text: '"$text"', style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: glass.textPrimary, fontSize: 14),
                ),
              ),
              Icon(LucideIcons.arrowRight, size: 16, color: glass.textSecondary),
            ],
          ),
        ),
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
/// cart as its own page. Follows the cart repository, so the count updates wherever items are added.
class CartButton extends StatefulWidget {
  const CartButton({super.key});

  @override
  State<CartButton> createState() => _CartButtonState();
}

class _CartButtonState extends State<CartButton> {
  @override
  void initState() {
    super.initState();
    // So the count is right before the cart page has been opened; loads only once
    context.read<CartRepository>().load();
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final count = context.watch<CartRepository>().itemCount;

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
  }
}
