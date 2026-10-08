// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/themes/glass_theme.dart';
import 'package:app/ui/shared/glass/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A group of settings: a small uppercase label on the background, then the rows in a glass card.
class SettingsGroup extends StatelessWidget {
  final String? title; // Null = no label
  final List<Widget> rows;

  const SettingsGroup({super.key, this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              title!.toUpperCase(),
              style: TextStyle(color: context.glass.textTertiary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1),
            ),
          ),
        GlassListCard(dividerIndent: 50, rows: rows), // Dividers start at the text, past the icons
      ],
    );
  }
}

/// One setting: icon (or a custom [leading]), title and optional subtitle, and on the right either
/// a [trailing] control or the current [value] with a chevron.
class SettingRow extends StatelessWidget {
  final IconData? icon;
  final Widget? leading; // Instead of the icon
  final String title;
  final String? subtitle;
  final String? value; // Current value, shown on the right
  final Widget? trailing;
  final VoidCallback? onTap; // Also shows a chevron when there's no trailing control

  const SettingRow({
    super.key,
    this.icon,
    this.leading,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
          child: Row(
            children: [
              leading ?? Icon(icon, size: 18, color: glass.textSecondary),
              SizedBox(width: leading != null ? 14 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: TextStyle(color: glass.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: TextStyle(color: glass.textTertiary, fontSize: 12)),
                    ],
                  ],
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: 8),
                Text(value!, style: TextStyle(color: glass.textSecondary, fontSize: 14)),
              ],
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
              if (onTap != null && trailing == null) ...[
                const SizedBox(width: 4),
                Icon(LucideIcons.chevronRight, size: 18, color: glass.textTertiary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Switch in the game's accent color.
class SettingSwitch extends StatelessWidget {
  final bool value;
  final Color accent;
  final ValueChanged<bool> onChanged;

  const SettingSwitch({super.key, required this.value, required this.accent, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Switch(
      value: value,
      activeThumbColor: accent,
      activeTrackColor: accent.withValues(alpha: 0.35),
      inactiveThumbColor: glass.textSecondary,
      inactiveTrackColor: glass.track,
      onChanged: onChanged,
    );
  }
}
