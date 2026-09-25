import 'dart:io';

import 'package:flutter/foundation.dart';

/// Build-time configuration from the env/*.env files, passed in with
/// `--dart-define-from-file=env/<name>.env`. Values are compiled into the app, so nothing here
/// is secret.
abstract final class Env {
  static const appEnv = String.fromEnvironment('APP_ENV');
  static const _apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static bool get isProd => appEnv == 'prod';
  static bool get isDev => appEnv == 'dev';

  /// On Android, localhost is the emulator itself; 10.0.2.2 is the host machine.
  static String get apiBaseUrl {
    if (Platform.isAndroid) {
      final uri = Uri.parse(_apiBaseUrl);
      if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
        return uri.replace(host: '10.0.2.2').toString();
      }
    }
    return _apiBaseUrl;
  }

  /// Fails fast on a misconfigured build: no env file passed, or a release build that isn't prod.
  static void validate() {
    if (appEnv.isEmpty || _apiBaseUrl.isEmpty) {
      throw StateError(
        'Missing env config. Run with --dart-define-from-file=env/dev.env (or env/prod.env).',
      );
    }
    if (kReleaseMode && !isProd) {
      throw StateError('Release builds must use env/prod.env, got APP_ENV=$appEnv.');
    }
  }
}
