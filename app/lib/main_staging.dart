// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/services/local/app_preferences.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import 'config/dependencies.dart';
import 'main.dart';

/// Staging config entry point.
/// launch with `flutter run --target lib/main_staging.dart`.
/// uses remote data from a server.
Future<void> main() async {
  Logger.root.level = Level.ALL;

  WidgetsFlutterBinding.ensureInitialized();
  await AppPreferences.load(); // Before the first screen: it depends on the saved game

  runApp(MultiProvider(providers: providersRemote, child: const MainApp()));
}
