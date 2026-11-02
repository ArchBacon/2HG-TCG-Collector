// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/domain/models/notification/received_notification.dart';
import 'package:app/themes/game_palette.dart';
import 'package:app/themes/glass_theme.dart';
import 'package:app/ui/notifications/view_models/notifications_viewmodel.dart';
import 'package:app/ui/shared/app_state.dart';
import 'package:app/ui/shared/glass/glass_card.dart';
import 'package:app/ui/shared/glass/glass_scaffold.dart';
import 'package:app/ui/shared/glass/loading_indicator.dart';
import 'package:app/ui/shared/view_model_host.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

/// The notifications this device received, newest first, opened from the top of the settings.
/// Unread ones have a dot; "Mark all as read" clears them and the badge on the Settings tab.
class NotificationsScreenContainer extends StatelessWidget {
  const NotificationsScreenContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelHost(
      create: (context) => NotificationsViewModel(repository: context.read()),
      builder: (context, viewModel) => NotificationsScreen(viewModel: viewModel),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  final NotificationsViewModel viewModel;

  const NotificationsScreen({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final game = selectedGame.value;
    final accent = GamePalette.of(context, game).accent;

    return ListenableBuilder(
      listenable: Listenable.merge([viewModel, viewModel.markAllRead]),
      builder: (context, _) {
        final notifications = viewModel.notifications;

        return GlassScaffold(
          game: game,
          title: 'Notifications',
          showGameSwitcher: false,
          children: [
            if (notifications == null)
              viewModel.load.running ? LoadingSection(color: accent) : const _Message("Couldn't load your notifications")
            else if (!viewModel.setUp)
              const _Message("Notifications aren't set up on this device yet. Allow notifications, and check back once one has come in.")
            else if (notifications.isEmpty)
              const _Message('No notifications yet. Wishlist cards that come into stock, and news and events from 2HG, show up here.')
            else ...[
              _Header(viewModel: viewModel, accent: accent),
              GlassListCard(
                dividerIndent: 52,
                rows: [
                  for (final notification in notifications)
                    _NotificationRow(
                      notification: notification,
                      accent: accent,
                      onTap: notification.route == null ? null : () => context.go(notification.route!),
                    ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

/// How many are unread, and the button to mark them all read.
class _Header extends StatelessWidget {
  final NotificationsViewModel viewModel;
  final Color accent;

  const _Header({required this.viewModel, required this.accent});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final unread = viewModel.unread;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              unread == 0 ? 'All read' : '$unread unread',
              style: TextStyle(color: glass.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton.icon(
            onPressed: unread == 0 || viewModel.markAllRead.running ? null : viewModel.markAllRead.execute,
            icon: Icon(LucideIcons.checkCheck, size: 16, color: unread == 0 ? glass.textTertiary : accent),
            label: Text(
              'Mark all as read',
              style: TextStyle(color: unread == 0 ? glass.textTertiary : accent, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  final ReceivedNotification notification;
  final Color accent;
  final VoidCallback? onTap;

  const _NotificationRow({required this.notification, required this.accent, this.onTap});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final unread = !notification.read;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(switch (notification.kind) {
                NotificationKind.wishlist => LucideIcons.sparkles,
                NotificationKind.announcement => LucideIcons.megaphone,
                NotificationKind.test => LucideIcons.bell,
              }, size: 20, color: unread ? glass.textPrimary : glass.textTertiary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            color: unread ? glass.textPrimary : glass.textSecondary,
                            fontSize: 15,
                            fontWeight: unread ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(_when(notification.sentAt), style: TextStyle(color: glass.textTertiary, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(notification.body, style: TextStyle(color: glass.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            // Unread dot
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 6),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: unread ? accent : Colors.transparent, shape: BoxShape.circle),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "Just now", "5 min", "3 h", "Yesterday", then the date.
  static String _when(DateTime sentAt) {
    final now = DateTime.now();
    final ago = now.difference(sentAt);
    if (ago.inMinutes < 1) return 'Just now';
    if (ago.inHours < 1) return '${ago.inMinutes} min';

    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(sentAt.year, sentAt.month, sentAt.day);
    if (day == today) return '${ago.inHours} h';
    if (today.difference(day).inDays == 1) return 'Yesterday';

    return DateFormat(sentAt.year == now.year ? 'd MMM' : 'd MMM y').format(sentAt);
  }
}

class _Message extends StatelessWidget {
  final String text;

  const _Message(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: context.glass.textSecondary)),
    );
  }
}
