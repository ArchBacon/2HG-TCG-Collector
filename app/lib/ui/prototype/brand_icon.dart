// Copyright 2026 Christian Delicaat. All rights reserved.

// PROTOTYPE: the app icon (branding/icon-color.svg), redrawn in code since the app has no SVG
// support yet. For the real app: add flutter_svg and use the file itself, so the two can't drift.

import 'dart:math';

import 'package:flutter/material.dart';

class BrandIcon extends StatelessWidget {
  final double size;

  const BrandIcon({super.key, this.size = 30});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'TCG Collector',
      image: true,
      child: CustomPaint(size: Size.square(size), painter: _BrandIconPainter()),
    );
  }
}

class _BrandIconPainter extends CustomPainter {
  static const _green = Color(0xFF5CB85C);
  static const _dark = Color(0xFF173D17);

  @override
  void paint(Canvas canvas, Size size) {
    // The SVG is drawn on a 100x100 grid. Without its rounded background, only the cards are drawn,
    // so zoom in on them (roughly x 17..83, y 18..84) to fill the icon's size.
    canvas.scale(size.width / 66);
    canvas.translate(-17, -18);

    // No background: the cards are drawn in the brand green instead of dark green, so they show on
    // both dark and light pages.

    // Three overlapping cards: (x, y, rotation in degrees around a center, opacity)
    void card(double x, double y, double degrees, Offset center, double opacity) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(degrees * pi / 180);
      canvas.translate(-center.dx, -center.dy);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, 38, 52), const Radius.circular(5)),
        Paint()..color = _green.withValues(alpha: opacity),
      );
      canvas.restore();
    }

    card(22, 30, -10, const Offset(41, 56), 0.35);
    card(40, 24, 8, const Offset(59, 50), 0.60);
    card(31, 22, 0, Offset.zero, 1);

    // Sparkle on the front card
    final sparkle = Path()
      ..moveTo(50, 36)
      ..lineTo(52, 42)
      ..lineTo(58, 44)
      ..lineTo(52, 46)
      ..lineTo(50, 52)
      ..lineTo(48, 46)
      ..lineTo(42, 44)
      ..lineTo(48, 42)
      ..close();
    canvas.drawPath(sparkle, Paint()..color = _dark);
  }

  @override
  bool shouldRepaint(_BrandIconPainter oldDelegate) => false;
}
