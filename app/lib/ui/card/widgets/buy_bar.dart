// Copyright 2026 Christian Delicaat. All rights reserved.

import 'dart:ui';

import 'package:app/domain/models/card/market_info.dart';
import 'package:app/themes/glass_theme.dart';
import 'package:app/tmp/core/utils/format.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Frosted bar over the bottom of the card page: the best listing's price and an "Add to cart"
/// button in the game's accent color.
class BuyBar extends StatelessWidget {
  final StoreListing listing;
  final String finish;
  final Color accent;
  final VoidCallback onAdd;

  const BuyBar({super.key, required this.listing, required this.finish, required this.accent, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, 14, 16, 14 + MediaQuery.paddingOf(context).bottom),
          decoration: BoxDecoration(
            color: glass.bar,
            border: Border(top: BorderSide(color: glass.edge)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatEuro(listing.price),
                      style: TextStyle(color: glass.textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    Text('${listing.condition} · $finish', style: TextStyle(color: glass.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: onAdd,
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: glass.onAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                icon: const Icon(LucideIcons.shoppingCart, size: 18),
                label: const Text('Add to cart'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
