// Copyright 2026 Christian Delicaat. All rights reserved.

import 'dart:typed_data';

import 'package:app/domain/models/scan/scan_match.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/utils/result.dart';

abstract class ScanRepository {
  /// Recognizes the card in [jpeg] (the card cut out of a camera frame, upright) as a card of
  /// [game] in the catalog. Fails with a [ScanException].
  Future<Result<ScanMatch>> scan(Tcg game, Uint8List jpeg);
}
