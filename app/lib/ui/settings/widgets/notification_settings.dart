// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/ui/settings/widgets/setting_row.dart';
import 'package:app/ui/shared/app_state.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Notification switches. "Wishlist cards in store" and "News and events" are saved and sent to
/// the API with the device (PushNotifications); price drops and order updates aren't built yet
/// and only toggle.
class NotificationSettings extends StatefulWidget {
  final Color accent;

  const NotificationSettings({super.key, required this.accent});

  @override
  State<NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<NotificationSettings> {
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
          subtitle: 'When a wishlisted card comes into stock at 2HG',
          trailing: ValueListenableBuilder(
            valueListenable: wishlistNotifications,
            builder: (context, on, _) =>
                SettingSwitch(value: on, accent: widget.accent, onChanged: (v) => wishlistNotifications.value = v),
          ),
        ),
        SettingRow(
          icon: LucideIcons.megaphone,
          title: 'News and events',
          subtitle: 'Events, new sets and offers from 2HG',
          trailing: ValueListenableBuilder(
            valueListenable: newsNotifications,
            builder: (context, on, _) =>
                SettingSwitch(value: on, accent: widget.accent, onChanged: (v) => newsNotifications.value = v),
          ),
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
