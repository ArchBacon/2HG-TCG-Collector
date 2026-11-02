// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/domain/models/card/market_info.dart';
import 'package:app/domain/models/collection/card_collection.dart';
import 'package:app/domain/models/collection/list_kind.dart';
import 'package:app/themes/glass_theme.dart';
import 'package:app/ui/shared/glass/glass_card.dart';
import 'package:app/ui/shared/glass/layout.dart';
import 'package:app/ui/shared/glass/option_sheet.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The user's lists of one kind on the card page: where the card is (with copies), and the list
/// the "add to" row adds to.
class ListRows {
  final ListKind kind;
  final List<(CardCollection, int)> heldIn; // Lists with copies, and how many
  final List<CardCollection> addOptions; // Lists it can be added to
  final CardCollection? addTarget; // Null = none to add to yet
  final void Function(String listId, int delta) onChange;
  final ValueChanged<CardCollection> onPickAddTarget;
  final ValueChanged<bool> onNewList; // Makes a list to add to; true: with a copy in it right away

  const ListRows({
    required this.kind,
    required this.heldIn,
    required this.addOptions,
    required this.addTarget,
    required this.onChange,
    required this.onPickAddTarget,
    required this.onNewList,
  });
}

/// Your copies per collection and per wishlist (a stepper each), with a row each to add the card
/// to a(nother) collection or wishlist; then how many other collectors have and want the card.
/// Copies are of the selected finish.
class OwnershipCard extends StatelessWidget {
  final ListRows collections;
  final ListRows wishlists;
  final MarketInfo market;
  final Color accent;

  const OwnershipCard({
    super.key,
    required this.collections,
    required this.wishlists,
    required this.market,
    required this.accent,
  });

  static String _compact(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';

  static String _addCaption(ListRows lists) =>
      lists.heldIn.isEmpty ? 'Add to ${lists.kind.name}' : 'Add to another ${lists.kind.name}';

  Future<void> _pick(BuildContext context, ListRows lists) async {
    final newList = 'New ${lists.kind.name}…';
    final picked = await showOptionSheet(
      context,
      title: _addCaption(lists),
      options: [for (final c in lists.addOptions) c.name, newList],
      current: lists.addTarget?.name ?? newList,
    );
    if (picked == null) return;
    if (picked == newList) {
      lists.onNewList(false);
    } else {
      lists.onPickAddTarget(lists.addOptions.firstWhere((c) => c.name == picked));
    }
  }

  List<Widget> _rows(BuildContext context, ListRows lists) {
    final icon = switch (lists.kind) {
      ListKind.collection => LucideIcons.layers,
      ListKind.wishlist => LucideIcons.heart,
    };
    final target = lists.addTarget;

    return [
      for (final (list, quantity) in lists.heldIn)
        _Row(
          icon: icon,
          title: _Title(caption: lists.kind == ListKind.collection ? 'In collection' : 'On wishlist', text: list.name),
          trailing: _Stepper(value: quantity, onChanged: (value) => lists.onChange(list.id, value - quantity)),
        ),
      _Row(
        icon: lists.heldIn.isEmpty ? icon : LucideIcons.plus,
        title: _Title(
          caption: _addCaption(lists),
          text: target?.name ?? 'New ${lists.kind.name}…',
          dropdown: true,
          accent: accent,
          onTap: () => _pick(context, lists),
        ),
        // Adding the first copy moves it up to its own row, and this one offers the next list
        trailing: _Stepper(value: 0, onChanged: (_) => target == null ? lists.onNewList(true) : lists.onChange(target.id, 1)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return GlassListCard(
      rows: [
        ..._rows(context, collections),
        ..._rows(context, wishlists),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Row(
            children: [
              Expanded(child: StatValue(value: _compact(market.have), label: 'Collectors have this')),
              Expanded(child: StatValue(value: _compact(market.want), label: 'Collectors want this')),
            ],
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final Widget title;
  final Widget trailing;

  const _Row({required this.icon, required this.title, required this.trailing});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          children: [
            Icon(icon, size: 18, color: glass.textSecondary),
            const SizedBox(width: 12),
            Expanded(child: title),
            trailing,
          ],
        ),
      ),
    );
  }
}

/// A row's text, with an optional caption above it. As a [dropdown], the text is the picked option,
/// in the accent color with a chevron, and tapping it opens the options.
class _Title extends StatelessWidget {
  final String? caption;
  final String text;
  final bool dropdown;
  final Color? accent;
  final VoidCallback? onTap;

  const _Title({this.caption, required this.text, this.dropdown = false, this.accent, this.onTap});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final color = dropdown ? accent ?? glass.textPrimary : glass.textPrimary;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (caption != null) Text(caption!, style: TextStyle(color: glass.textTertiary, fontSize: 12)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: color, fontSize: 15, fontWeight: dropdown ? FontWeight.w600 : FontWeight.w500),
              ),
            ),
            if (dropdown) ...[const SizedBox(width: 4), Icon(LucideIcons.chevronDown, size: 16, color: color)],
          ],
        ),
      ],
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: content),
    );
  }
}

/// Minus / count / plus; minus is disabled at 0.
class _Stepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _Stepper({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    Widget button(IconData icon, String tooltip, VoidCallback? onTap) => IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      color: glass.textPrimary,
      disabledColor: glass.textTertiary,
      style: IconButton.styleFrom(backgroundColor: glass.fill),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        button(LucideIcons.minus, 'One less', value > 0 ? () => onChanged(value - 1) : null),
        SizedBox(
          width: 32,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: TextStyle(color: glass.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        button(LucideIcons.plus, 'One more', () => onChanged(value + 1)),
      ],
    );
  }
}
