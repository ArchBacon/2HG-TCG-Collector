// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/services/remote/push_notifications.dart';
import 'package:app/routing/routes.dart';
import 'package:app/themes/glass_theme.dart';
import 'package:app/ui/settings/widgets/setting_row.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The top of the settings: opens the notifications this device received, with the unread count.
class NotificationsEntry extends StatelessWidget {
  const NotificationsEntry({super.key});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return SettingsGroup(
      rows: [
        SettingRow(
          icon: LucideIcons.bell,
          title: 'Notifications',
          subtitle: 'Received on this device',
          // Under the settings page it's on: the tab's, or the start screen's
          onTap: () => context.go('${GoRouterState.of(context).uri.path}/${Routes.notificationsPath}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder(
                valueListenable: PushNotifications.unread,
                builder: (context, unread, _) => unread == 0
                    ? const SizedBox.shrink()
                    : Badge(
                        label: Text('$unread'),
                        backgroundColor: glass.badge,
                        textColor: glass.onBadge,
                      ),
              ),
              const SizedBox(width: 4),
              Icon(LucideIcons.chevronRight, size: 18, color: glass.textTertiary),
            ],
          ),
        ),
      ],
    );
  }
}
