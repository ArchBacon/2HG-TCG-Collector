// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/services/local/app_preferences.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import 'main.dart';
import 'config/dependencies.dart';

/// Development config entry point.
/// launch with `flutter run --target lib/main_development.dart`.
/// uses local data.
Future<void> main() async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((r) => debugPrint('${r.level.name} ${r.loggerName}: ${r.message} ${r.error ?? ''}'));

  WidgetsFlutterBinding.ensureInitialized();
  await AppPreferences.load(); // Before the first screen: it depends on the saved game

  runApp(MultiProvider(providers: providersLocal, child: const MainApp()));
}
