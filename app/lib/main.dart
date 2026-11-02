// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/services/remote/push_notifications.dart';
import 'package:app/localization/app_localizations.dart';
import 'package:app/routing/router.dart';
import 'package:app/themes/theme.dart';
import 'package:app/ui/shared/notification_banner.dart';
import 'package:app/ui/shared/app_state.dart';
import 'package:flutter/material.dart';

import 'main_development.dart' as development;

/// Default main method
void main() {
  // Launch development config by default
  development.main();
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  // Created once, so rebuilding the app (e.g. on a theme change) keeps the current page
  final _router = router();

  @override
  void initState() {
    super.initState();
    // A tapped notification opens its page, also one that started the app
    PushNotifications.openedRoute.addListener(_openNotificationRoute);
    WidgetsBinding.instance.addPostFrameCallback((_) => _openNotificationRoute());
  }

  @override
  void dispose() {
    PushNotifications.openedRoute.removeListener(_openNotificationRoute);
    super.dispose();
  }

  void _openNotificationRoute() {
    final route = PushNotifications.openedRoute.value;
    if (route == null) return;
    PushNotifications.openedRoute.value = null;
    _router.go(route);
  }

  @override
  Widget build(BuildContext context) {
    // The theme mode is picked in the settings. The glass styling is part of both themes
    // (GlassTheme), so switching animates everything over without rebuilding the pages.
    return ValueListenableBuilder(
      valueListenable: themeModeSetting,
      builder: (context, themeMode, _) => MaterialApp.router(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: _router,
        builder: (context, child) => ColoredBox(
          color: Theme.of(context).colorScheme.surface,
          // Notifications that arrive while the app is open show as a banner over every page
          child: NotificationBanner(
            onOpen: _router.go,
            child: SafeArea(top: false, child: child!),
          ),
        ),
      ),
    );
  }
}
