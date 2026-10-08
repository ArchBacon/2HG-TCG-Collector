// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/ui/settings/widgets/setting_row.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Notification switches. They toggle, but aren't saved or acted on yet.
class NotificationSettings extends StatefulWidget {
  final Color accent;

  const NotificationSettings({super.key, required this.accent});

  @override
  State<NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<NotificationSettings> {
  var _newInStore = true;
  var _priceDrops = false;
  var _orders = true;

  @override
  Widget build(BuildContext context) {
    return SettingsGroup(
      title: 'Notifications',
      rows: [
        SettingRow(
          icon: LucideIcons.sparkles,
          title: 'Wishlist cards in store',
          subtitle: 'When a wishlisted card is added to the store',
          trailing: SettingSwitch(value: _newInStore, accent: widget.accent, onChanged: (v) => setState(() => _newInStore = v)),
        ),
        SettingRow(
          icon: LucideIcons.trendingDown,
          title: 'Price drops',
          subtitle: 'On cards in your wishlist',
          trailing: SettingSwitch(value: _priceDrops, accent: widget.accent, onChanged: (v) => setState(() => _priceDrops = v)),
        ),
        SettingRow(
          icon: LucideIcons.package,
          title: 'Order updates',
          trailing: SettingSwitch(value: _orders, accent: widget.accent, onChanged: (v) => setState(() => _orders = v)),
        ),
      ],
    );
  }
}
