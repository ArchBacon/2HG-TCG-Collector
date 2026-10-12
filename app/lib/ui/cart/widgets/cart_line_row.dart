// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/domain/models/cart/cart_line.dart';
import 'package:app/routing/navigation.dart';
import 'package:app/themes/glass_theme.dart';
import 'package:app/tmp/core/utils/format.dart';
import 'package:app/ui/shared/glass/card_thumb.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// One cart line: the card, its set and number, finish and condition, the line price and a
/// quantity stepper. Tapping it opens the card.
class CartLineRow extends StatelessWidget {
  final CartLine line;
  final ValueChanged<int> onQuantityChanged; // 0 = remove the line

  const CartLineRow({super.key, required this.line, required this.onQuantityChanged});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return InkWell(
      onTap: () => context.openCard(line.card),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Row(
          children: [
            CardThumb(game: line.card.game, width: 48, radius: 5),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.card.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: glass.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${line.card.setName} · ${line.card.number}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: glass.textTertiary, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${line.finish} · ${line.condition}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: glass.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatEuro(line.card.price * line.quantity),
                    style: TextStyle(color: glass.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            _QuantityStepper(line: line, onChanged: onQuantityChanged),
          ],
        ),
      ),
    );
  }
}

/// Minus / count / plus in a pill. Minus at 1 becomes a bin and removes the line.
class _QuantityStepper extends StatelessWidget {
  final CartLine line;
  final ValueChanged<int> onChanged;

  const _QuantityStepper({required this.line, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Container(
      decoration: BoxDecoration(
        color: glass.fill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: glass.edge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: line.quantity == 1 ? 'Remove' : 'One less',
            visualDensity: VisualDensity.compact,
            onPressed: () => onChanged(line.quantity - 1),
            icon: Icon(line.quantity == 1 ? LucideIcons.trash2 : LucideIcons.minus, size: 15),
            color: glass.textPrimary,
          ),
          Text('${line.quantity}', style: TextStyle(color: glass.textPrimary, fontWeight: FontWeight.w700)),
          IconButton(
            tooltip: 'One more',
            visualDensity: VisualDensity.compact,
            onPressed: () => onChanged(line.quantity + 1),
            icon: const Icon(LucideIcons.plus, size: 15),
            color: glass.textPrimary,
          ),
        ],
      ),
    );
  }
}
