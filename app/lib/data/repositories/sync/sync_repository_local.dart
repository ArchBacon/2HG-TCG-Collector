// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/sync/sync_repository.dart';
import 'package:app/data/services/local/local_data_service.dart';
import 'package:app/domain/models/user/sync_code.dart';
import 'package:app/utils/result.dart';

class SyncRepositoryLocal implements SyncRepository {
  SyncRepositoryLocal({required this._localDataService});

  final LocalDataService _localDataService;

  @override
  Future<Result<SyncCode>> createSyncCode() async {
    try {
      return Result.ok(await _localDataService.createSyncCode());
    } on Exception catch (error) {
      return Result.error(error);
    }
  }

  /// There's no other device's user to continue as without the server.
  @override
  Future<Result<void>> redeemSyncCode(String code) async =>
      const Result.error(RedeemSyncCodeException(RedeemFailure.unavailable));
}
