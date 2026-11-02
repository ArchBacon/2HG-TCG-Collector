// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/services/remote/push_notifications.dart';
import 'package:app/ui/shared/glass_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Wraps the top-level tabs with the bottom navigation bar. Each tab keeps its own navigation stack.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// Order must match the branches in the router.
  static final _items = [
    const GlassNavItem(icon: LucideIcons.library, label: 'Catalog'),
    const GlassNavItem(icon: LucideIcons.layers, label: 'Collection'),
    const GlassNavItem(icon: LucideIcons.heart, label: 'Wishlist'),
    // The unread notifications, which open from the top of the settings
    GlassNavItem(icon: LucideIcons.settings, label: 'Settings', badge: PushNotifications.unread),
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
