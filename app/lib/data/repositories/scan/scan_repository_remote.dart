// Copyright 2026 Christian Delicaat. All rights reserved.

import 'dart:typed_data';

import 'package:app/data/repositories/scan/scan_repository.dart';
import 'package:app/data/services/local/remote_data_service.dart';
import 'package:app/domain/models/scan/scan_match.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/utils/result.dart';

/// Scans go to the API, which has Magic Sorter recognize them and finds the card.
class ScanRepositoryRemote implements ScanRepository {
  ScanRepositoryRemote({required this._remoteDataService});

  final RemoteDataService _remoteDataService;

  @override
  Future<Result<ScanMatch>> scan(Tcg game, Uint8List jpeg) async {
    if (!game.canScan) return const Result.error(ScanException(ScanFailure.unsupported));
    try {
      return Result.ok(await _remoteDataService.scanCard(game, jpeg));
    } on ScanException catch (error) {
      return Result.error(error);
    } on Exception {
      return const Result.error(ScanException(ScanFailure.unavailable));
    }
  }
}
