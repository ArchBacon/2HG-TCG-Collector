import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/env.dart';

const _tokenKey = 'api_token';

// The token belongs to this device only: readable after the first unlock following a reboot
// (so background work can use it), and never synced to iCloud or restored onto another device.
const _storage = FlutterSecureStorage(
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
);

/// The token saved on this device, or null if there is none. Read once and cached for the app's lifetime.
final storedTokenProvider = FutureProvider<String?>((ref) => getStoredToken());

Future<String?> loadOrCreateToken() async {
  final stored = await getStoredToken();

  if (stored != null) {
    try {
      final validateRes = await http.get(
        Uri.parse('${Env.apiBaseUrl}/api/users/validate'),
        headers: {
          'Authorization': 'Bearer $stored',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      // Only a 401 means the token is bad; any other failure (offline, server error) keeps it.
      if (validateRes.statusCode != 401) return stored;
      await _storage.delete(key: _tokenKey);
    } catch (e) {
      debugPrint('Token validation failed, keeping stored token: $e');
      return stored;
    }
  }

  try {
    final createRes = await http.post(
        Uri.parse('${Env.apiBaseUrl}/api/users'),
        headers: {'Accept': 'application/json'}
    ).timeout(const Duration(seconds: 5));

    if (createRes.statusCode != 201) return null;

    final token = (jsonDecode(createRes.body) as Map<String, dynamic>)['token'] as String;
    await _storage.write(key: _tokenKey, value: token);
    return token;
  } catch (e) {
    debugPrint('Creating user failed: $e');
    return null;
  }
}

/// Stored data can become unreadable, e.g. after an Android backup restore where the encryption
/// key didn't come along. Treat that as "no token" instead of crashing on startup.
Future<String?> getStoredToken() async {
  try {
    return await _storage.read(key: _tokenKey);
  } catch (e) {
    debugPrint('Reading stored token failed, clearing storage: $e');
    await _storage.deleteAll();
    return null;
  }
}