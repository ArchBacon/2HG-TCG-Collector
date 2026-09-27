// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:flutter/material.dart';

/// Colors from the Google Stitch design.
abstract final class AppColors {
  static const brandGreen = Color(0xFF5CB85C);

  static const background = Color(0xFF10141A);
  static const card = Color(0xFF181C22);
  static const cardBorder = Color(0x0FFFFFFF); // white 6%

  /// Tiles and pills inside a card.
  static const inset = Color(0x08FFFFFF); // white 3%
  static const insetBorder = Color(0x0DFFFFFF); // white 5%

  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFF0F3FF);
  static const textMuted = Color(0xFF8B9BB4);
}
