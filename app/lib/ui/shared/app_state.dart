// Copyright 2026 Christian Delicaat. All rights reserved.

// App-wide UI state shared by the screens, until it moves into view models / settings storage.

import 'package:app/tmp/shared/models/tcg.dart';
import 'package:flutter/material.dart';

/// The game the screens show, picked with the game switcher in the header. Null = all games.
final selectedGame = ValueNotifier<Tcg?>(Tcg.pokemon);

/// The search text in the header, shared by every tab. Searches the selected game's catalog.
final cardSearch = ValueNotifier('');

/// Light / dark / system, picked in the settings.
final themeModeSetting = ValueNotifier(ThemeMode.dark);
