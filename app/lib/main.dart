// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/localization/app_localizations.dart';
import 'package:app/routing/router.dart';
import 'package:app/themes/theme.dart';
import 'package:app/ui/prototype/glass.dart';
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
  // Created once, so rebuilding the app (e.g. on a theme change) keeps the current page.
  final _router = router();

  @override
  Widget build(BuildContext context) {
    // PROTOTYPE: the theme mode comes from the prototype settings.
    return ValueListenableBuilder(
      valueListenable: protoThemeMode,
      builder: (context, themeMode, _) => MaterialApp.router(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: _router,
        builder: (context, child) {
          // PROTOTYPE: the prototype's colors read this; keying on it rebuilds every page when it
          // changes, since many of its widgets are const and wouldn't pick up the change otherwise.
          final brightness = switch (themeMode) {
            ThemeMode.light => Brightness.light,
            ThemeMode.dark => Brightness.dark,
            ThemeMode.system => MediaQuery.platformBrightnessOf(context),
          };
          ProtoTheme.brightness = brightness;

          return ColoredBox(
            color: Theme.of(context).colorScheme.surface,
            child: SafeArea(top: false, child: KeyedSubtree(key: ValueKey(brightness), child: child!)),
          );
        },
      ),
    );
  }
}
