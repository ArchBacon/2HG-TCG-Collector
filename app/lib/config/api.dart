// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Where the API lives, per build flavor. Compiled into the app, so nothing here is secret.
abstract final class Api {
  // TODO: replace with the real production API URL.
  static const _productionUrl = 'https://api.example.com';
  static const _developmentUrl = 'http://localhost:8000';

  /// Set with `--dart-define=API_URL=...` to use another API, e.g. on a real phone, where
  /// 10.0.2.2 doesn't lead to the PC: `http://localhost:8000` with `adb reverse tcp:8000 tcp:8000`,
  /// or the PC's address on the network. Taken as is, also for the production flavor.
  static const _overrideUrl = String.fromEnvironment('API_URL');

  /// The [_overrideUrl] when given; otherwise the production URL for the production flavor and the
  /// local dev API for the others. On Android, localhost is the emulator itself, so it's swapped
  /// for 10.0.2.2 (the host machine).
  static String get baseUrl {
    if (_overrideUrl.isNotEmpty) return _overrideUrl.replaceFirst(RegExp(r'/+$'), ''); // Paths are appended with a "/"
    if (appFlavor == 'production') return _productionUrl;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _developmentUrl.replaceFirst('localhost', '10.0.2.2');
    }
    return _developmentUrl;
  }
}
