// Copyright 2026 Christian Delicaat. All rights reserved.

/// A short-lived code to continue as this user on another device. Can be used once.
class SyncCode {
  final String code;
  final DateTime expiresAt;

  const SyncCode({required this.code, required this.expiresAt});

  /// How long it's still valid; zero once it has expired.
  Duration get remaining {
    final left = expiresAt.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  bool get expired => remaining == Duration.zero;
}

/// Why redeeming a sync code failed.
enum RedeemFailure {
  invalidCode, // Unknown, already used or expired
  ownCode, // A code of this device's own user
  tooManyAttempts,
  unavailable, // No server to redeem it with, or it couldn't be reached
}

class RedeemSyncCodeException implements Exception {
  final RedeemFailure failure;

  const RedeemSyncCodeException(this.failure);

  @override
  String toString() => 'RedeemSyncCodeException(${failure.name})';
}
