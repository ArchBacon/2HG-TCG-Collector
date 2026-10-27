// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/sync/sync_repository.dart';
import 'package:app/data/services/local/remote_data_service.dart';
import 'package:app/data/services/remote/user_token.dart';
import 'package:app/domain/models/user/sync_code.dart';
import 'package:app/utils/result.dart';

class SyncRepositoryRemote implements SyncRepository {
  SyncRepositoryRemote({required this._remoteDataService});

  final RemoteDataService _remoteDataService;

  @override
  Future<Result<SyncCode>> createSyncCode() async {
    try {
      return Result.ok(await _remoteDataService.createSyncCode());
    } on Exception catch (error) {
      return Result.error(error);
    }
  }

  @override
  Future<Result<void>> redeemSyncCode(String code) async {
    try {
      final token = await _remoteDataService.redeemSyncCode(code);
      await UserToken.replace(token);
      return const Result.ok(null);
    } on RedeemSyncCodeException catch (error) {
      return Result.error(error);
    } on Exception {
      return const Result.error(RedeemSyncCodeException(RedeemFailure.unavailable));
    }
  }
}
