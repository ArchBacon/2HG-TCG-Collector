// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/services/local/app_preferences.dart';
import 'package:app/data/services/remote/push_notifications.dart';
import 'package:app/data/services/remote/user_token.dart';
import 'package:app/ui/offline/offline_app.dart';
import 'package:app/ui/shared/app_state.dart';
import 'package:flutter/foundation.dart';
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
  if (kDebugMode) {
    Logger.root.onRecord.listen((r) => debugPrint('${r.level.name} ${r.loggerName}: ${r.message} ${r.error ?? ''}'));
  }

  WidgetsFlutterBinding.ensureInitialized();
  await AppPreferences.load(); // Before the first screen: it depends on the saved game
  final info = await PackageInfo.fromPlatform();
  appVersion = info.version;
  await _start();
}

/// Connects to the API and starts the app; when the API can't be reached, shows the offline
/// screen instead, whose button runs this again.
Future<void> _start() async {
  // Ensure the anonymous user exists, for the API calls
  final token = await UserToken.loadOrCreate();
  if (token == null) {
    runApp(const OfflineApp(onRetry: _start));
    return;
  }
  UserToken.current.value = token;
  // Registers this device for wishlist notifications, as that user
  await PushNotifications.start();

  // A new token (after redeeming a sync code) means another user: everything is built again for
  // it, from the start screen, so no data of the previous user is kept
  runApp(
    ValueListenableBuilder(
      valueListenable: UserToken.current,
      builder: (context, token, _) => MultiProvider(
        key: ValueKey(token),
        providers: providersRemote(token: token),
        child: const MainApp(),
      ),
    ),
  );
}
