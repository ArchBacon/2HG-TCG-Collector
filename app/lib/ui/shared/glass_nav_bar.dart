// Copyright 2026 Christian Delicaat. All rights reserved.

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../tmp/shared/theme/app_colors.dart';

/// A single tab in a [GlassNavBar].
class GlassNavItem {
  final IconData icon;
  final String label;

  const GlassNavItem({required this.icon, required this.label});
}

/// Bottom navigation bar with the same frosted-glass look as the GlassAppBar.
///
/// Use with `Scaffold(extendBody: true)` so the content actually scrolls behind it,
/// and pad the bottom of the scrolling content by [GlassNavBar.contentBottomPadding].
class GlassNavBar extends StatelessWidget {
  final List<GlassNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const GlassNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  static const height = 64.0;

  /// Height the nav bar covers at the bottom of the screen.
  static double contentBottomPadding(BuildContext context) =>
      MediaQuery.paddingOf(context).bottom;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            // Page background at 40%; light page color on light theme
            color: isDark ? const Color(0x6610141A) : const Color(0x80F4F6FA),
            border: Border(top: BorderSide(color: isDark ? AppColors.cardBorder : const Color(0x14000000))),
          ),
          child: SizedBox(
            height: height,
            child: Row(
              children: [
                for (final (index, item) in items.indexed)
                  Expanded(
                    child: _NavButton(
                      item: item,
                      selected: index == selectedIndex,
                      onTap: () => onSelected(index),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final GlassNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = selected
        ? (isDark ? AppColors.brandGreen : const Color(0xFF2E8B3E)) // Deeper green on light, for contrast
        : (isDark ? AppColors.textMuted : const Color(0xFF5B6575));

    return InkResponse(
      onTap: onTap,
      radius: 32,
      child: Semantics(
        selected: selected,
        button: true,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pill behind the selected icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? AppColors.brandGreen.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(item.icon, size: 20, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
