// Copyright 2026 Christian Delicaat. All rights reserved.

import 'dart:convert';

import 'package:app/config/api.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

/// The anonymous user's API token. Created by the API on first launch, then saved on the device
/// and sent with every API call as `Authorization: Bearer <token>`. Replaced when this device
/// redeems another device's sync code.
abstract final class UserToken {
  static const _tokenKey = 'api_token';
  static final _log = Logger('UserToken');

  // The token belongs to this device only: readable after the first unlock following a reboot
  // (so background work can use it), and never synced to iCloud or restored onto another device.
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );

  /// The token in use: set on startup, and changed by [replace]. The app's dependencies are built
  /// for it, and built again when it changes (main_production).
  static final current = ValueNotifier<String?>(null);

  /// Saves [token] in place of the current one, and switches the app over to it.
  static Future<void> replace(String token) async {
    await _storage.write(key: _tokenKey, value: token);
    current.value = token;
  }

  /// The saved token if the API still accepts it, otherwise a newly created one. Null when there
  /// is none and the API can't be reached to create one. Call before runApp.
  static Future<String?> loadOrCreate() async {
    final stored = await _read();

    if (stored != null) {
      try {
        final response = await http
            .get(
              Uri.parse('${Api.baseUrl}/api/users/validate'),
              headers: {'Authorization': 'Bearer $stored', 'Accept': 'application/json'},
            )
            .timeout(const Duration(seconds: 5));

        // Only a 401 means the token is bad; any other failure (offline, server error) keeps it
        if (response.statusCode != 401) return stored;
        await _storage.delete(key: _tokenKey);
      } catch (error) {
        _log.warning('Validating the token failed, keeping the stored one', error);
        return stored;
      }
    }

    try {
      final response = await http
          .post(Uri.parse('${Api.baseUrl}/api/users'), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 201) {
        _log.warning('Creating a user failed with status ${response.statusCode}');
        return null;
      }

      final token = (jsonDecode(response.body) as Map<String, dynamic>)['token'] as String;
      await _storage.write(key: _tokenKey, value: token);
      return token;
    } catch (error) {
      _log.warning('Creating a user failed', error);
      return null;
    }
  }

  /// Stored data can become unreadable, e.g. after an Android backup restore where the encryption
  /// key didn't come along. Treat that as "no token" instead of crashing on startup.
  static Future<String?> _read() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (error) {
      _log.warning('Reading the stored token failed, clearing storage', error);
      await _storage.deleteAll();
      return null;
    }
  }
}
