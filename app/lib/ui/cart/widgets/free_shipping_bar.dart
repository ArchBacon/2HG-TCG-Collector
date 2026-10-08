// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/themes/colors.dart';
import 'package:app/themes/glass_theme.dart';
import 'package:app/tmp/core/utils/format.dart';
import 'package:app/ui/shared/glass/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// "Add €X for free shipping", with a bar showing how close the cart is.
class FreeShippingBar extends StatelessWidget {
  final double missing; // Euros still to add
  final double progress; // 0..1

  const FreeShippingBar({super.key, required this.missing, required this.progress});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.truck, size: 16, color: glass.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Add ${formatEuro(missing)} for free shipping',
                  style: TextStyle(color: glass.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
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
              color: AppColors.brandGreen,
              backgroundColor: glass.track,
            ),
          ),
        ],
      ),
    );
  }
}
