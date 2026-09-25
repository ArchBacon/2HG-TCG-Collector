import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Startup work that must finish before the first frame (e.g. ensuring the
  // anonymous identity exists) goes here, before runApp.

  runApp(const ProviderScope(child: App()));
}
