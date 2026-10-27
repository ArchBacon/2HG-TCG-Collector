// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/sync/sync_repository.dart';
import 'package:app/domain/models/user/sync_code.dart';
import 'package:app/utils/command.dart';
import 'package:app/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Creates sync codes, and keeps the last one while it's valid; and redeems another device's code.
class SyncCodeViewModel extends ChangeNotifier {
  SyncCodeViewModel({required this._syncRepository}) {
    create = Command0(_create);
    redeem = Command1(_redeem);
  }

  final SyncRepository _syncRepository;
  final _log = Logger('SyncCodeViewModel');

  late final Command0<SyncCode> create;

  /// Takes the code as typed. On success the app reloads as the other device's user.
  late final Command1<void, String> redeem;

  SyncCode? _code;

  /// The last code created, while it's still valid; null before that and once it has expired.
  SyncCode? get code => _code == null || _code!.expired ? null : _code;

  /// Why the last redeem failed; null when it didn't (or hasn't run).
  RedeemFailure? get redeemFailure => switch (redeem.result) {
    Error(error: RedeemSyncCodeException(:final failure)) => failure,
    Error() => RedeemFailure.unavailable,
    _ => null,
  };

  Future<Result<SyncCode>> _create() async {
    final result = await _syncRepository.createSyncCode();
    switch (result) {
      case Ok(:final value):
        _code = value;
        notifyListeners();
      case Error(:final error):
        _log.warning('Failed to create a sync code', error);
    }
    return result;
  }

  Future<Result<void>> _redeem(String code) async {
    final result = await _syncRepository.redeemSyncCode(code.trim().toUpperCase());
    if (result case Error(:final error)) _log.warning('Failed to redeem a sync code', error);
    return result;
  }
}
