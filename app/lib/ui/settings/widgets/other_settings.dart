// Copyright 2026 Christian Delicaat. All rights reserved.

// The settings groups that are only placeholders for now: their rows don't do anything yet.

import 'package:app/ui/settings/widgets/setting_row.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Orders, shipping, payment and currency.
class StoreSettings extends StatelessWidget {
  const StoreSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsGroup(
      title: 'Store',
      rows: [
        SettingRow(icon: LucideIcons.receipt, title: 'Orders', onTap: () {}),
        SettingRow(icon: LucideIcons.mapPin, title: 'Shipping address', onTap: () {}),
        SettingRow(icon: LucideIcons.creditCard, title: 'Payment methods', onTap: () {}),
        SettingRow(icon: LucideIcons.euro, title: 'Currency', value: 'EUR (€)', onTap: () {}),
      ],
    );
  }
}

/// Export, import and card language.
class CollectionDataSettings extends StatelessWidget {
  const CollectionDataSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsGroup(
      title: 'Collection data',
      rows: [
        SettingRow(icon: LucideIcons.download, title: 'Export collection', subtitle: 'CSV or JSON', onTap: () {}),
        SettingRow(icon: LucideIcons.upload, title: 'Import from another app', onTap: () {}),
        SettingRow(icon: LucideIcons.languages, title: 'Card language', value: 'English', onTap: () {}),
      ],
    );
  }
}

/// Version, terms and privacy.
class AboutSettings extends StatelessWidget {
  const AboutSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsGroup(
      title: 'About',
      rows: [
        const SettingRow(icon: LucideIcons.info, title: 'Version', value: '0.1.0'),
        SettingRow(icon: LucideIcons.fileText, title: 'Terms & privacy', onTap: () {}),
      ],
    );
  }
}
