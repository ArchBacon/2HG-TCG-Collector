// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/domain/models/user/sync_code.dart';
import 'package:app/utils/result.dart';

abstract class SyncRepository {
  /// A new code to continue as this user on another device.
  Future<Result<SyncCode>> createSyncCode();

  /// Continues as the user of another device's [code]: this device's own collection and lists are
  /// dropped. On success the app reloads with the new user (see UserToken.current). Fails with a
  /// [RedeemSyncCodeException].
  Future<Result<void>> redeemSyncCode(String code);
}
