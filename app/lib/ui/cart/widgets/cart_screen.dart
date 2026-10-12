// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/ui/cart/view_models/cart_viewmodel.dart';
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
  final CartViewModel viewModel;

  const CartScreen({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final lines = viewModel.lines;

        return GlassScaffold(
          game: null,
          title: lines.isEmpty ? 'Cart' : 'Cart · ${viewModel.itemCount}',
          showCart: false,
          showGameSwitcher: false,
          children: [
            if (lines.isEmpty)
              const EmptyCartCard()
            else ...[
              if (viewModel.shipping > 0) ...[
                FreeShippingBar(
                  missing: CartViewModel.freeShippingFrom - viewModel.subtotal,
                  progress: viewModel.subtotal / CartViewModel.freeShippingFrom,
                ),
                const SizedBox(height: 14),
              ],
              for (final MapEntry(key: game, value: gameLines) in viewModel.linesByGame.entries) ...[
                SectionHeading(game.displayName),
                GlassListCard(
                  dividerIndent: 76, // Lines up with the text, past the card image
                  rows: [
                    for (final line in gameLines)
                      CartLineRow(line: line, onQuantityChanged: (quantity) => viewModel.setQuantity.execute((line, quantity))),
                  ],
                ),
                const SizedBox(height: 20),
              ],
              CartSummary(subtotal: viewModel.subtotal, shipping: viewModel.shipping),
            ],
          ],
        );
      },
    );
  }
}
