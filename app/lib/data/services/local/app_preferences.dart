// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/ui/shared/app_state.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Saves the app state that should survive a restart (the last game, whether to open it on start,
/// and the theme mode), and restores it on launch.
abstract final class AppPreferences {
  static const _lastGameKey = 'lastGame';
  static const _openLastGameKey = 'openLastGameOnStart';
  static const _themeModeKey = 'themeMode';

  /// Restores the saved state into [selectedGame], [openLastGameOnStart] and [themeModeSetting],
  /// and keeps saving them when they change. Call before runApp.
  static Future<void> load() async {
    final prefs = SharedPreferencesAsync();

    final lastGame = await prefs.getString(_lastGameKey);
    final game = Tcg.values.where((t) => t.slug == lastGame).firstOrNull;
    if (game != null) selectedGame.value = game;

    openLastGameOnStart.value = await prefs.getBool(_openLastGameKey) ?? false;

    // Stored by name: 'system', 'light' or 'dark'
    final themeMode = await prefs.getString(_themeModeKey);
    final mode = ThemeMode.values.where((m) => m.name == themeMode).firstOrNull;
    if (mode != null) themeModeSetting.value = mode;

    selectedGame.addListener(() => prefs.setString(_lastGameKey, selectedGame.value.slug));
    openLastGameOnStart.addListener(() => prefs.setBool(_openLastGameKey, openLastGameOnStart.value));
    themeModeSetting.addListener(() => prefs.setString(_themeModeKey, themeModeSetting.value.name));
  }
}
