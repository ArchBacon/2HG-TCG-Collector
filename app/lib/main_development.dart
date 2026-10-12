// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/services/local/app_preferences.dart';
import 'package:app/ui/shared/app_state.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
  final info = await PackageInfo.fromPlatform();
  appVersion = info.version;

  runApp(MultiProvider(providers: providersLocal, child: const MainApp()));
}
