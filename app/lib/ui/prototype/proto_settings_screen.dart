// Copyright 2026 Christian Delicaat. All rights reserved.

// PROTOTYPE: Settings tab. Grouped glass lists. The backdrop style, default game and notification
// switches work; the rest are placeholders. Also links to the extra prototype variants.

import 'package:app/routing/routes.dart';
import 'package:app/ui/prototype/game_switcher.dart';
import 'package:app/ui/prototype/glass.dart';
import 'package:app/ui/prototype/proto_common.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ProtoSettingsScreen extends StatefulWidget {
  const ProtoSettingsScreen({super.key});

  @override
  State<ProtoSettingsScreen> createState() => _ProtoSettingsScreenState();
}

class _ProtoSettingsScreenState extends State<ProtoSettingsScreen> {
  var _notifyNewInStore = true;
  var _notifyPriceDrops = false;
  var _notifyOrders = true;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: protoGame,
      builder: (context, game, _) {
        final accent = GamePalette.of(game).accent;

        return ProtoScaffold(
          game: game,
          title: 'Settings',
          showGameSwitcher: false,
          children: [
            // Account
            ProtoListCard(
              rows: [
                _SettingRow(
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
                  onTap: () {},
                ),
              ],
            ),

            _Section('Appearance'),
            ProtoListCard(
              dividerIndent: 50,
              rows: [
                _SettingRow(
                  icon: LucideIcons.sunMoon,
                  title: 'Theme',
                  trailing: ValueListenableBuilder(
                    valueListenable: protoThemeMode,
                    builder: (context, mode, _) => SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      style: SegmentedButton.styleFrom(
                        foregroundColor: GlassText.secondary,
                        selectedForegroundColor: accent,
                        selectedBackgroundColor: accent.withValues(alpha: 0.18),
                        side: BorderSide(color: GlassColors.current.edge),
                        visualDensity: VisualDensity.compact,
                      ),
                      segments: const [
                        ButtonSegment(value: ThemeMode.system, icon: Icon(LucideIcons.smartphone, size: 16), tooltip: 'System'),
                        ButtonSegment(value: ThemeMode.light, icon: Icon(LucideIcons.sun, size: 16), tooltip: 'Light'),
                        ButtonSegment(value: ThemeMode.dark, icon: Icon(LucideIcons.moon, size: 16), tooltip: 'Dark'),
                      ],
                      selected: {mode},
                      onSelectionChanged: (s) => protoThemeMode.value = s.first,
                    ),
                  ),
                ),
                _SettingRow(
                  icon: LucideIcons.image,
                  title: 'Background',
                  trailing: ValueListenableBuilder(
                    valueListenable: protoBackdropStyle,
                    builder: (context, style, _) => SegmentedButton<BackdropStyle>(
                      showSelectedIcon: false,
                      style: SegmentedButton.styleFrom(
                        foregroundColor: GlassText.secondary,
                        selectedForegroundColor: accent,
                        selectedBackgroundColor: accent.withValues(alpha: 0.18),
                        side: BorderSide(color: GlassColors.current.edge),
                        visualDensity: VisualDensity.compact,
                      ),
                      segments: const [
                        ButtonSegment(value: BackdropStyle.cards, label: Text('Cards')),
                        ButtonSegment(value: BackdropStyle.mesh, label: Text('Colors')),
                        ButtonSegment(value: BackdropStyle.artwork, label: Text('Artwork')),
                      ],
                      selected: {style},
                      onSelectionChanged: (s) => protoBackdropStyle.value = s.first,
                    ),
                  ),
                ),
                _SettingRow(
                  icon: LucideIcons.layoutGrid,
                  title: 'Game',
                  value: game?.displayName ?? 'All games',
                  onTap: () async {
                    final picked = await showGameSheet(context, current: game);
                    if (picked != null) protoGame.value = picked.game;
                  },
                ),
              ],
            ),

            _Section('Notifications'),
            ProtoListCard(
              dividerIndent: 50,
              rows: [
                _SettingRow(
                  icon: LucideIcons.sparkles,
                  title: 'Wishlist cards in store',
                  subtitle: 'When a wishlisted card is added to the store',
                  trailing: _Switch(value: _notifyNewInStore, accent: accent, onChanged: (v) => setState(() => _notifyNewInStore = v)),
                ),
                _SettingRow(
                  icon: LucideIcons.trendingDown,
                  title: 'Price drops',
                  subtitle: 'On cards in your wishlist',
                  trailing: _Switch(value: _notifyPriceDrops, accent: accent, onChanged: (v) => setState(() => _notifyPriceDrops = v)),
                ),
                _SettingRow(
                  icon: LucideIcons.package,
                  title: 'Order updates',
                  trailing: _Switch(value: _notifyOrders, accent: accent, onChanged: (v) => setState(() => _notifyOrders = v)),
                ),
              ],
            ),

            _Section('Store'),
            ProtoListCard(
              dividerIndent: 50,
              rows: [
                _SettingRow(icon: LucideIcons.receipt, title: 'Orders', onTap: () {}),
                _SettingRow(icon: LucideIcons.mapPin, title: 'Shipping address', onTap: () {}),
                _SettingRow(icon: LucideIcons.creditCard, title: 'Payment methods', onTap: () {}),
                _SettingRow(icon: LucideIcons.euro, title: 'Currency', value: 'EUR (€)', onTap: () {}),
              ],
            ),

            _Section('Collection data'),
            ProtoListCard(
              dividerIndent: 50,
              rows: [
                _SettingRow(icon: LucideIcons.download, title: 'Export collection', subtitle: 'CSV or JSON', onTap: () {}),
                _SettingRow(icon: LucideIcons.upload, title: 'Import from another app', onTap: () {}),
                _SettingRow(icon: LucideIcons.languages, title: 'Card language', value: 'English', onTap: () {}),
              ],
            ),

            _Section('Prototype variants'),
            ProtoListCard(
              dividerIndent: 50,
              rows: [
                _SettingRow(
                  icon: LucideIcons.layoutDashboard,
                  title: 'Wishlist layout A',
                  subtitle: 'Glass style 1, set grids',
                  onTap: () => context.push(Routes.protoMesh),
                ),
                _SettingRow(
                  icon: LucideIcons.panelsTopLeft,
                  title: 'Wishlist layout B',
                  subtitle: 'Artwork backdrop, open header, list rows',
                  onTap: () => context.push(Routes.protoArtwork),
                ),
              ],
            ),

            _Section('About'),
            ProtoListCard(
              dividerIndent: 50,
              rows: [
                _SettingRow(icon: LucideIcons.info, title: 'Version', value: '0.1.0 (prototype)'),
                _SettingRow(icon: LucideIcons.fileText, title: 'Terms & privacy', onTap: () {}),
              ],
            ),
          ],
        );
      },
    );
  }
}

// Small uppercase label above a group, straight on the backdrop.
class _Section extends StatelessWidget {
  final String title;

  const _Section(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(color: GlassText.tertiary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData? icon;
  final Widget? leading; // Instead of the icon
  final String title;
  final String? subtitle;
  final String? value; // Current value, shown on the right with a chevron
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingRow({
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
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
          child: Row(
            children: [
              leading ?? Icon(icon, size: 18, color: GlassText.secondary),
              SizedBox(width: leading != null ? 14 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: TextStyle(color: GlassText.primary, fontSize: 15, fontWeight: FontWeight.w500)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: TextStyle(color: GlassText.tertiary, fontSize: 12)),
                    ],
                  ],
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: 8),
                Text(value!, style: TextStyle(color: GlassText.secondary, fontSize: 14)),
              ],
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
              if (onTap != null && trailing == null) ...[
                const SizedBox(width: 4),
                Icon(LucideIcons.chevronRight, size: 18, color: GlassText.tertiary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Switch extends StatelessWidget {
  final bool value;
  final Color accent;
  final ValueChanged<bool> onChanged;

  const _Switch({required this.value, required this.accent, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      activeThumbColor: accent,
      activeTrackColor: accent.withValues(alpha: 0.35),
      inactiveThumbColor: GlassText.secondary,
      inactiveTrackColor: GlassColors.current.track,
      onChanged: onChanged,
    );
  }
}
