// Copyright 2026 Christian Delicaat. All rights reserved.

import 'dart:async';
import 'dart:ui';

import 'package:app/data/services/remote/push_notifications.dart';
import 'package:app/themes/glass_theme.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Shows a notification that arrives while the app is open (PushNotifications.inApp) as a banner
/// over the top of every page: the system shows nothing then. Tapping it opens its page with
/// [onOpen]; it slides away after a few seconds, or when swiped up.
class NotificationBanner extends StatefulWidget {
  final Widget child;
  final void Function(String route) onOpen;

  const NotificationBanner({super.key, required this.child, required this.onOpen});

  @override
  State<NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<NotificationBanner> {
  static const _shownFor = Duration(seconds: 6);
  static const _slide = Duration(milliseconds: 280);

  InAppNotification? _notification;
  var _visible = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    PushNotifications.inApp.addListener(_show);
  }

  @override
  void dispose() {
    PushNotifications.inApp.removeListener(_show);
    _hideTimer?.cancel();
    super.dispose();
  }

  void _show() {
    final notification = PushNotifications.inApp.value;
    if (notification == null) return;
    PushNotifications.inApp.value = null;

    setState(() {
      _notification = notification;
      _visible = true;
    });
    _hideTimer?.cancel();
    _hideTimer = Timer(_shownFor, _hide);
  }

  void _hide() {
    _hideTimer?.cancel();
    if (mounted) setState(() => _visible = false);
  }

  void _open() {
    final route = _notification?.route;
    _hide();
    if (route != null) widget.onOpen(route);
  }

  @override
  Widget build(BuildContext context) {
    final notification = _notification;

    return Stack(
      children: [
        widget.child,
        if (notification != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: AnimatedSlide(
                offset: _visible ? Offset.zero : const Offset(0, -1.6),
                duration: _slide,
                curve: _visible ? Curves.easeOutCubic : Curves.easeInCubic,
                child: AnimatedOpacity(
                  opacity: _visible ? 1 : 0,
                  duration: _slide,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: GestureDetector(
                      onVerticalDragEnd: (details) {
                        if ((details.primaryVelocity ?? 0) < 0) _hide(); // Swiped up
                      },
                      child: _BannerCard(notification: notification, onTap: _open),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  final InAppNotification notification;
  final VoidCallback onTap;

  const _BannerCard({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final radius = BorderRadius.circular(20);

    // A real blur, like the app bar: the page under it isn't blurred already
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Material(
          color: glass.bar,
          shape: RoundedRectangleBorder(borderRadius: radius, side: BorderSide(color: glass.edge)),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: glass.fill, borderRadius: BorderRadius.circular(12)),
                    child: Icon(
                      notification.isAnnouncement ? LucideIcons.megaphone : LucideIcons.sparkles,
                      size: 18,
                      color: glass.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: glass.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        if (notification.body.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            notification.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: glass.textSecondary, fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
