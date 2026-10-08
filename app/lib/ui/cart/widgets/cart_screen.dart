// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/services/mock/mock_cart.dart';
import 'package:app/domain/models/cart/cart_line.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/ui/cart/widgets/cart_line_row.dart';
import 'package:app/ui/cart/widgets/cart_summary.dart';
import 'package:app/ui/cart/widgets/empty_cart_card.dart';
import 'package:app/ui/cart/widgets/free_shipping_bar.dart';
import 'package:app/ui/shared/glass/glass_card.dart';
import 'package:app/ui/shared/glass/glass_scaffold.dart';
import 'package:app/ui/shared/glass/layout.dart';
import 'package:flutter/material.dart';

/// The cart, opened from the cart button in the header. Lines grouped per game (a cart can mix
/// games), a free-shipping nudge, the order summary and checkout.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  static const _freeShippingFrom = 50.0;
  static const _shippingCost = 4.95;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: cart,
      builder: (context, lines, _) {
        final subtotal = lines.fold(0.0, (sum, l) => sum + l.card.price * l.quantity);
        final shipping = subtotal >= _freeShippingFrom || lines.isEmpty ? 0.0 : _shippingCost;
        final count = lines.fold(0, (n, l) => n + l.quantity);

        return GlassScaffold(
          game: null,
          title: lines.isEmpty ? 'Cart' : 'Cart · $count',
          showCart: false,
          showGameSwitcher: false,
          children: [
            if (lines.isEmpty)
              const EmptyCartCard()
            else ...[
              if (shipping > 0) ...[
                FreeShippingBar(missing: _freeShippingFrom - subtotal, progress: subtotal / _freeShippingFrom),
                const SizedBox(height: 14),
              ],
              for (final MapEntry(key: game, value: gameLines) in _groupByGame(lines).entries) ...[
                SectionHeading(game.displayName),
                GlassListCard(
                  dividerIndent: 76, // Lines up with the text, past the card image
                  rows: [for (final line in gameLines) CartLineRow(line: line)],
                ),
                const SizedBox(height: 20),
              ],
              CartSummary(subtotal: subtotal, shipping: shipping),
            ],
          ],
        );
      },
    );
  }

  static Map<Tcg, List<CartLine>> _groupByGame(List<CartLine> lines) {
    final groups = <Tcg, List<CartLine>>{};
    for (final line in lines) {
      groups.putIfAbsent(line.card.game, () => []).add(line);
    }
    return groups;
  }
}
