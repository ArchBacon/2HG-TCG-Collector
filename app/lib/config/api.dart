// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Where the API lives, per build flavor. Compiled into the app, so nothing here is secret.
abstract final class Api {
  // TODO: replace with the real production API URL.
  static const _productionUrl = 'https://api.example.com';
  static const _developmentUrl = 'http://localhost:8000';

  /// The production URL for the production flavor, the local dev API otherwise. On Android,
  /// localhost is the emulator itself, so it's swapped for 10.0.2.2 (the host machine).
  static String get baseUrl {
    if (appFlavor == 'production') return _productionUrl;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _developmentUrl.replaceFirst('localhost', '10.0.2.2');
    }
    return _developmentUrl;
  }
}
