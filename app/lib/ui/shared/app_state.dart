// Copyright 2026 Christian Delicaat. All rights reserved.

// App-wide UI state shared by the screens, until it moves into view models / settings storage.
// selectedGame, openLastGameOnStart and themeModeSetting are saved between launches
// (AppPreferences).

import 'package:app/tmp/shared/models/tcg.dart';
import 'package:flutter/material.dart';

/// The game the tabs show. Picked on the start screen, or with the game switcher in the header.
final selectedGame = ValueNotifier<Tcg>(Tcg.pokemon);

/// Skip the start screen on launch and open the last game straight away.
final openLastGameOnStart = ValueNotifier(false);

/// The search text in the header, shared by every tab. Searches the selected game's catalog.
final cardSearch = ValueNotifier('');

/// Light / dark / system, picked in the settings.
final themeModeSetting = ValueNotifier(ThemeMode.system);

/// The installed app's version and build number, e.g. '0.0.1 (1)'. From pubspec.yaml at build
/// time; set in main before runApp.
late final String appVersion;
