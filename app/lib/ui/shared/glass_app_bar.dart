// Copyright 2026 Christian Delicaat. All rights reserved.

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../tmp/shared/theme/app_colors.dart';

/// App bar with a frosted-glass look: content scrolling underneath is blurred and shows through
/// a translucent tint.
///
/// Use with `Scaffold(extendBodyBehindAppBar: true)` so the content actually scrolls behind it,
/// and pad the top of the scrolling content by [GlassAppBar.contentTopPadding].
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading; // Null = the default (a back button on pushed pages)
  final double? leadingWidth;
  final double? titleSpacing;
  final PreferredSizeWidget? bottom; // Second row under the title row, inside the same glass

  const GlassAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.leadingWidth,
    this.titleSpacing,
    this.bottom,
  });

  /// Height the app bar covers, including the status bar.
  static double contentTopPadding(BuildContext context) =>
      MediaQuery.paddingOf(context).top;

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // The shadow is drawn outside the app bar's bounds, so it needs a Stack that doesn't clip.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AppBar(
          title: title,
          actions: actions,
          leading: leading,
          leadingWidth: leadingWidth,
          titleSpacing: titleSpacing,
          bottom: bottom,
          // Material 3 tints the bar green (the primary color) once content scrolls under it.
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  // Page background at 40%; light page color on light theme
                  color: isDark ? const Color(0x6610141A) : const Color(0x80F4F6FA),
                  border: Border(bottom: BorderSide(color: isDark ? AppColors.cardBorder : const Color(0x14000000))),
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
        // Shadow below the bar: a dark strip fading out downwards. A BoxShadow would also darken
        // the area under the glass itself, making the bar less transparent.
        const Positioned(
          left: 0,
          right: 0,
          bottom: -16, // Starts at the bar's bottom edge
          height: 16, // Shadow length
          child: IgnorePointer( // Taps go through to the content underneath
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x40000000), Color(0x00000000)], // Black 25% to transparent
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
