// Copyright 2026 Christian Delicaat. All rights reserved.

import 'dart:typed_data';

import 'package:app/data/repositories/scan/scan_repository.dart';
import 'package:app/domain/models/scan/scan_match.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/utils/result.dart';

/// Recognizing a card needs the server (and Magic Sorter behind it).
class ScanRepositoryLocal implements ScanRepository {
  @override
  Future<Result<ScanMatch>> scan(Tcg game, Uint8List jpeg) async =>
      const Result.error(ScanException(ScanFailure.unavailable));
}
