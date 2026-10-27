// Copyright 2026 Christian Delicaat. All rights reserved.

import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Small card images kept on the device, for the cards in the user's collections and wishlist: they
/// load from here first, and are downloaded (and kept) only when they aren't here yet. Cleared from
/// the settings.
abstract final class CardImageStore {
  static Future<Directory>? _dir;

  /// The folder the images are kept in, made when needed.
  static Future<Directory> _directory() => _dir ??= () async {
    final support = await getApplicationSupportDirectory();
    return Directory('${support.path}${Platform.pathSeparator}card_images').create(recursive: true);
  }();

  /// The file for [url]: its path, made safe as a file name (the API's paths are unique per image).
  static Future<File> _fileFor(String url) async {
    final name = Uri.parse(url).path.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return File('${(await _directory()).path}${Platform.pathSeparator}$name');
  }

  /// The image at [url]: from the device when it's there, otherwise downloaded and kept. Throws an
  /// [HttpException] when the download fails.
  static Future<Uint8List> load(String url) async {
    final file = await _fileFor(url);
    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      if (bytes.isNotEmpty) return bytes;
    }

    final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
      throw HttpException('GET $url failed with status ${response.statusCode}', uri: Uri.parse(url));
    }
    // Written to a temporary file first, so a half-written image is never read back
    final partial = File('${file.path}.part');
    await partial.writeAsBytes(response.bodyBytes, flush: true);
    await partial.rename(file.path);
    return response.bodyBytes;
  }

  /// Bytes in use, and the number of images.
  static Future<({int bytes, int count})> usage() async {
    var bytes = 0;
    var count = 0;
    await for (final entity in (await _directory()).list()) {
      if (entity is File && !entity.path.endsWith('.part')) {
        bytes += await entity.length();
        count++;
      }
    }
    return (bytes: bytes, count: count);
  }

  /// Deletes every kept image; they download again when next shown.
  static Future<void> clear() async {
    final dir = await _directory();
    if (await dir.exists()) await dir.delete(recursive: true);
    _dir = null;
  }
}
