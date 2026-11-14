// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/domain/models/card/market_info.dart';
import 'package:app/themes/glass_theme.dart';
import 'package:app/tmp/core/utils/format.dart';
import 'package:app/ui/shared/glass/glass_card.dart';
import 'package:flutter/material.dart';

/// The card's market prices for the selected [finish]: one row per source (Cardmarket, TCGplayer),
/// in the source's own currency, with when the source last updated it. Says so when there's none.
class PriceCard extends StatelessWidget {
  final MarketInfo market;
  final String finish; // The API's id of the selected finish
  final String finishLabel; // As the screens show it, e.g. "Foil"

  const PriceCard({super.key, required this.market, required this.finish, required this.finishLabel});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final prices = market.pricesFor(finish);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Market price', style: TextStyle(color: glass.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          if (prices.isEmpty)
            Text(
              market.prices.isEmpty ? 'No market price for this card' : 'No market price for the $finishLabel finish',
              style: TextStyle(color: glass.textTertiary, fontSize: 14),
            )
          else
            for (final (i, price) in prices.indexed) ...[
              if (i > 0) Divider(height: 20, color: glass.divider),
              _PriceRow(price: price),
            ],
        ],
      ),
    );
  }
}

/// One source's price: its name and which price it is on the left, the amount on the right.
class _PriceRow extends StatelessWidget {
  final MarketPrice price;

  const _PriceRow({required this.price});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                price.source.label,
                style: TextStyle(color: glass.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                '${price.source.kind} · ${_updated(price.updatedAt)}',
                style: TextStyle(color: glass.textTertiary, fontSize: 12),
              ),
            ],
          ),
        ),
        Text(
          formatMoney(price.price, price.currency),
          style: TextStyle(
            color: glass.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  /// "updated today", "updated yesterday", "updated 29 Aug".
  static String _updated(DateTime at) {
    final local = at.toLocal();
    final today = DateUtils.dateOnly(DateTime.now());
    final days = today.difference(DateUtils.dateOnly(local)).inDays;
    if (days <= 0) return 'updated today';
    if (days == 1) return 'updated yesterday';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final year = local.year == today.year ? '' : ' ${local.year}';
    return 'updated ${local.day} ${months[local.month - 1]}$year';
  }
}
