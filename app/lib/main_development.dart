// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import 'main.dart';
import 'config/dependencies.dart';

/// Development config entry point.
/// launch with `flutter run --target lib/main_development.dart`.
/// uses local data.
void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((r) => debugPrint('${r.level.name} ${r.loggerName}: ${r.message} ${r.error ?? ''}'));

  runApp(MultiProvider(providers: providersLocal, child: const MainApp()));
}
