// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/routing/routes.dart';
import 'package:app/themes/glass_theme.dart';
import 'package:app/ui/shared/glass/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Shown instead of the lines when the cart is empty, pointing to the wishlist.
class EmptyCartCard extends StatelessWidget {
  const EmptyCartCard({super.key});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        children: [
          Icon(LucideIcons.shoppingCart, size: 36, color: glass.textSecondary),
          const SizedBox(height: 12),
          Text('Your cart is empty', style: TextStyle(color: glass.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'Cards from your wishlist that are in store are a good place to start.',
            textAlign: TextAlign.center,
            style: TextStyle(color: glass.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            onPressed: () => context.go(Routes.wishlist),
            style: OutlinedButton.styleFrom(foregroundColor: glass.textPrimary, side: BorderSide(color: glass.edge)),
            child: const Text('Go to wishlist'),
          ),
        ],
      ),
    );
  }
}
