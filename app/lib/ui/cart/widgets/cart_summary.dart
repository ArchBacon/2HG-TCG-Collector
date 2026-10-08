// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/themes/colors.dart';
import 'package:app/themes/glass_theme.dart';
import 'package:app/tmp/core/utils/format.dart';
import 'package:app/ui/shared/glass/glass_card.dart';
import 'package:flutter/material.dart';

/// Subtotal, shipping and total, with the checkout button under it.
class CartSummary extends StatelessWidget {
  final double subtotal;
  final double shipping; // 0 = free

  const CartSummary({super.key, required this.subtotal, required this.shipping});

  @override
  Widget build(BuildContext context) {
    final total = subtotal + shipping;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassCard(
          child: Column(
            children: [
              _SummaryRow('Subtotal', formatEuro(subtotal)),
              const SizedBox(height: 8),
              _SummaryRow('Shipping', shipping == 0 ? 'Free' : formatEuro(shipping)),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: context.glass.divider),
              ),
              _SummaryRow('Total', formatEuro(total), bold: true),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Checkout isn\'t built yet')),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandGreen,
              foregroundColor: const Color(0xFF0A0E12), // Dark text on the brand green, in both themes
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            child: Text('Checkout · ${formatEuro(total)}'),
          ),
        ),
      ],
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
    final glass = context.glass;
    final style = TextStyle(
      color: bold ? glass.textPrimary : glass.textSecondary,
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
