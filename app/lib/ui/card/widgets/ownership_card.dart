// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/domain/models/card/market_info.dart';
import 'package:app/themes/glass_theme.dart';
import 'package:app/ui/shared/glass/glass_card.dart';
import 'package:app/ui/shared/glass/layout.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Your copies (stepper) and wishlist status (switch), and how many other collectors have and want
/// the card.
class OwnershipCard extends StatelessWidget {
  final int owned;
  final bool wishlisted;
  final MarketInfo market;
  final Color accent;
  final ValueChanged<int> onOwnedChanged;
  final ValueChanged<bool> onWishlistedChanged;

  const OwnershipCard({
    super.key,
    required this.owned,
    required this.wishlisted,
    required this.market,
    required this.accent,
    required this.onOwnedChanged,
    required this.onWishlistedChanged,
  });

  static String _compact(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';

  @override
  Widget build(BuildContext context) {
    return GlassListCard(
      rows: [
        _Row(
          icon: LucideIcons.layers,
          title: 'In your collection',
          trailing: _Stepper(value: owned, onChanged: onOwnedChanged),
        ),
        _Row(
          icon: LucideIcons.heart,
          title: 'On your wishlist',
          trailing: Switch(
            value: wishlisted,
            activeThumbColor: accent,
            activeTrackColor: accent.withValues(alpha: 0.35),
            onChanged: onWishlistedChanged,
          ),
        ),
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
  final String title;
  final Widget trailing;

  const _Row({required this.icon, required this.title, required this.trailing});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            Icon(icon, size: 18, color: glass.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: TextStyle(color: glass.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
            ),
            trailing,
          ],
        ),
      ),
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
