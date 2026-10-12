// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/services/local/app_preferences.dart';
import 'package:app/ui/shared/app_state.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import 'config/dependencies.dart';
import 'main.dart';

/// Production config entry point.
/// launch with `flutter run --flavor production --target lib/main_production.dart`.
/// uses remote data from a server.
Future<void> main() async {
  Logger.root.level = Level.ALL;

  WidgetsFlutterBinding.ensureInitialized();
  await AppPreferences.load(); // Before the first screen: it depends on the saved game
  final info = await PackageInfo.fromPlatform();
  appVersion = info.version;

  runApp(MultiProvider(providers: providersRemote, child: const MainApp()));
}
