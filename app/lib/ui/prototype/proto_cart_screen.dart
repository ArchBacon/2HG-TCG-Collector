// Copyright 2026 Christian Delicaat. All rights reserved.

// PROTOTYPE: Cart tab. Lines grouped per game (a cart can mix games), quantity steppers, a
// free-shipping nudge, the order summary and a checkout button. Cards added from the card details
// page show up here.

import 'package:app/routing/routes.dart';
import 'package:app/tmp/core/utils/format.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/ui/prototype/glass.dart';
import 'package:app/ui/prototype/proto_common.dart';
import 'package:app/ui/prototype/proto_data.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ProtoCartScreen extends StatelessWidget {
  const ProtoCartScreen({super.key});

  static const _freeShippingFrom = 50.0;
  static const _shipping = 4.95;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: protoCart,
      builder: (context, lines, _) {
        final subtotal = lines.fold(0.0, (sum, l) => sum + l.card.price * l.quantity);
        final shipping = subtotal >= _freeShippingFrom || lines.isEmpty ? 0.0 : _shipping;
        final count = lines.fold(0, (n, l) => n + l.quantity);
        final byGame = <Tcg, List<CartLine>>{};
        for (final line in lines) {
          byGame.putIfAbsent(line.card.game, () => []).add(line);
        }

        return ProtoScaffold(
          game: null,
          title: lines.isEmpty ? 'Cart' : 'Cart · $count',
          showCart: false,
          showGameSwitcher: false,
          children: [
            if (lines.isEmpty)
              GlassCard(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  children: [
                    Icon(LucideIcons.shoppingCart, size: 36, color: GlassText.secondary),
                    const SizedBox(height: 12),
                    Text(
                      'Your cart is empty',
                      style: TextStyle(color: GlassText.primary, fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Cards from your wishlist that are in store are a good place to start.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: GlassText.secondary, fontSize: 14),
                    ),
                    const SizedBox(height: 18),
                    OutlinedButton(
                      onPressed: () => context.go(Routes.wishlist),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: GlassText.primary,
                        side: BorderSide(color: GlassColors.current.edge),
                      ),
                      child: const Text('Go to wishlist'),
                    ),
                  ],
                ),
              )
            else ...[
              // Free shipping nudge
              if (shipping > 0) ...[
                _FreeShippingBar(missing: _freeShippingFrom - subtotal, progress: subtotal / _freeShippingFrom),
                const SizedBox(height: 14),
              ],

              // Lines per game
              for (final MapEntry(key: game, value: gameLines) in byGame.entries) ...[
                ProtoHeading(game.displayName),
                ProtoListCard(
                  dividerIndent: 76,
                  rows: [for (final line in gameLines) _LineRow(line: line)],
                ),
                const SizedBox(height: 20),
              ],

              // Summary
              GlassCard(
                child: Column(
                  children: [
                    _SummaryRow('Subtotal', formatEuro(subtotal)),
                    const SizedBox(height: 8),
                    _SummaryRow('Shipping', shipping == 0 ? 'Free' : formatEuro(shipping)),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1, color: GlassColors.current.divider),
                    ),
                    _SummaryRow('Total', formatEuro(subtotal + shipping), bold: true),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Prototype: checkout isn\'t built')),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF5CB85C),
                    foregroundColor: const Color(0xFF0A0E12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  child: Text('Checkout · ${formatEuro(subtotal + shipping)}'),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _FreeShippingBar extends StatelessWidget {
  final double missing;
  final double progress;

  const _FreeShippingBar({required this.missing, required this.progress});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.truck, size: 16, color: GlassText.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Add ${formatEuro(missing)} for free shipping',
                  style: TextStyle(color: GlassText.primary, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 4,
              color: const Color(0xFF5CB85C),
              backgroundColor: GlassColors.current.track,
            ),
          ),
        ],
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  final CartLine line;

  const _LineRow({required this.line});

  void _setQuantity(int quantity) {
    final lines = [...protoCart.value];
    final index = lines.indexOf(line);
    if (quantity == 0) {
      lines.removeAt(index);
    } else {
      lines[index] = line.withQuantity(quantity);
    }
    protoCart.value = lines;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => openCard(context, line.card),
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
                    style: TextStyle(color: GlassText.primary, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${line.card.setName} · ${line.card.number}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: GlassText.tertiary, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${line.finish} · ${line.condition}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: GlassText.secondary, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatEuro(line.card.price * line.quantity),
                    style: TextStyle(color: GlassText.primary, fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            // Quantity: minus at 1 removes the line
            Container(
              decoration: BoxDecoration(
                color: GlassColors.of(context).fill,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: GlassColors.current.edge),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _setQuantity(line.quantity - 1),
                    icon: Icon(line.quantity == 1 ? LucideIcons.trash2 : LucideIcons.minus, size: 15),
                    color: GlassText.primary,
                  ),
                  Text('${line.quantity}', style: TextStyle(color: GlassText.primary, fontWeight: FontWeight.w700)),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _setQuantity(line.quantity + 1),
                    icon: const Icon(LucideIcons.plus, size: 15),
                    color: GlassText.primary,
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

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _SummaryRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: bold ? GlassText.primary : GlassText.secondary,
      fontSize: bold ? 17 : 14,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
    );
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: style),
      ],
    );
  }
}
