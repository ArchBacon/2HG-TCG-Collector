// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/themes/glass_theme.dart';
import 'package:app/ui/shared/glass/glass_card.dart';
import 'package:flutter/material.dart';

/// Totals across all games at the top of the start screen: cards collected and wishlisted, spread
/// evenly across the card, each centered with its label under the number.
class TotalsCard extends StatelessWidget {
  final int collected;
  final int wishlisted;

  const TotalsCard({super.key, required this.collected, required this.wishlisted});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Total(label: 'Collected', value: collected),
          _Total(label: 'Wishlisted', value: wishlisted),
        ],
      ),
    );
  }
}

class _Total extends StatelessWidget {
  final String label;
  final int value;

  const _Total({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    // Number above the label, like the other stats (StatValue)
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            color: glass.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            height: 1.1,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: glass.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
