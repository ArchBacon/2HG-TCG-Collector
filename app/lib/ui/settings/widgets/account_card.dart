// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/ui/settings/widgets/setting_row.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The account at the top of the settings. Not signed in yet: invites to sign in.
class AccountCard extends StatelessWidget {
  final Color accent;

  const AccountCard({super.key, required this.accent});

  @override
  Widget build(BuildContext context) {
    return SettingsGroup(
      rows: [
        SettingRow(
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.2),
              border: Border.all(color: accent.withValues(alpha: 0.5)),
            ),
            child: Icon(LucideIcons.user, size: 20, color: accent),
          ),
          title: 'Guest',
          subtitle: 'Sign in to sync your collection across devices',
          onTap: () {}, // TODO: sign in
        ),
      ],
    );
  }
}
