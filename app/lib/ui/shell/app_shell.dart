// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/ui/shared/glass_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Wraps the top-level tabs with the bottom navigation bar. Each tab keeps its own navigation stack.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// Order must match the branches in the router.
  static const _items = [
    GlassNavItem(icon: LucideIcons.layers, label: 'Collection'),
    GlassNavItem(icon: LucideIcons.heart, label: 'Wishlist'),
    GlassNavItem(icon: LucideIcons.library, label: 'Catalog'),
    GlassNavItem(icon: LucideIcons.settings, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: GlassNavBar(
        items: _items,
        selectedIndex: navigationShell.currentIndex,

        // Tapping the current tab again pops it back to its first page.
        onSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
