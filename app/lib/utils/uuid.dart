// Copyright 2026 Christian Delicaat. All rights reserved.

import 'dart:math';

final _random = Random.secure();

/// A random (version 4) UUID, e.g. for ids the app makes before the API knows them.
String uuidV4() {
  final bytes = [for (var i = 0; i < 16; i++) _random.nextInt(256)];
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // Version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // Variant 1
  final hex = [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')].join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
