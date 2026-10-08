// Copyright 2026 Christian Delicaat. All rights reserved.

import 'dart:math';

import 'package:app/domain/models/card/market_info.dart';
import 'package:app/themes/glass_theme.dart';
import 'package:app/tmp/core/utils/format.dart';
import 'package:app/ui/shared/glass/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Market price, its change over 7 days, and a 30-day price line.
class PriceCard extends StatelessWidget {
  final double price;
  final MarketInfo market;
  final Color accent; // Line color

  const PriceCard({super.key, required this.price, required this.market, required this.accent});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final up = market.change7d >= 0;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Market price', style: TextStyle(color: glass.textSecondary, fontSize: 13)),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                formatEuro(price),
                style: TextStyle(
                  color: glass.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 10),
              GlassChip(
                icon: up ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                label: '${up ? '+' : ''}${market.change7d.toStringAsFixed(1)}% · 7d',
                color: up ? glass.positive : glass.negative,
                filled: true,
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 64,
            width: double.infinity,
            child: CustomPaint(painter: _Sparkline(market.history, accent)),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('30 days ago', style: TextStyle(color: glass.textTertiary, fontSize: 11)),
              const Spacer(),
              Text('Today', style: TextStyle(color: glass.textTertiary, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Price line with a soft fill under it and a dot on today's price.
class _Sparkline extends CustomPainter {
  final List<double> values;
  final Color color;

  _Sparkline(this.values, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final low = values.reduce(min);
    final high = values.reduce(max);
    final range = high - low == 0 ? 1 : high - low;

    Offset point(int i) => Offset(
      size.width * i / (values.length - 1),
      size.height - (values[i] - low) / range * (size.height - 4) - 2,
    );

    final line = Path()..moveTo(point(0).dx, point(0).dy);
    for (var i = 1; i < values.length; i++) {
      line.lineTo(point(i).dx, point(i).dy);
    }
    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(point(values.length - 1), 3.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_Sparkline oldDelegate) => oldDelegate.values != values || oldDelegate.color != color;
}
