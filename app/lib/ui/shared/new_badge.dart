// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:flutter/material.dart';

import '../../tmp/shared/theme/app_colors.dart';

// Small dark pill marking something as new, e.g. "3 new" or "New".
// No backdrop blur: at this size it's barely visible, and many of them in a scrolling list caused
// artifacts. A darker tint keeps the text readable on top of artwork instead.
class NewBadge extends StatelessWidget {
  final String label;
  final bool small; // Smaller text and padding, e.g. on card thumbnails

  const NewBadge({super.key, required this.label, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: small
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 1)
          : const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xB310141A), // Page background at 70%
        borderRadius: BorderRadius.circular(999), // Fully rounded ends
        border: Border.all(color: AppColors.brandGreen.withValues(alpha: 0.4)), // Thin green edge
        boxShadow: const [
          BoxShadow(color: Color(0x59000000), blurRadius: 8, offset: Offset(0, 2)), // Black 35%, like the card shadow but smaller
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.brandGreen,
          fontSize: small ? 10 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
