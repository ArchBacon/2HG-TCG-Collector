import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/home/screens/home.dart';
import 'core/config/env.dart';
import 'core/identity/token.dart';


Future<void> main() async {
  Env.validate();
  WidgetsFlutterBinding.ensureInitialized();

  // Only allow portrait mode
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Ensure the anonymous identity exists, before the app runs.
  await loadOrCreateToken();

  // Start app
  runApp(const ProviderScope(child: MaterialApp(
    home: Home(),
  )));
}
