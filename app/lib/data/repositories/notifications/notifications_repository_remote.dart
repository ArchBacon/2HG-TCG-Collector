// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/notifications/notifications_repository.dart';
import 'package:app/data/services/local/remote_data_service.dart';
import 'package:app/data/services/remote/push_notifications.dart';
import 'package:app/domain/models/notification/received_notification.dart';
import 'package:app/utils/result.dart';

/// From the API, for this device by its Firebase Installation ID (PushNotifications.fid).
class NotificationsRepositoryRemote implements NotificationsRepository {
  NotificationsRepositoryRemote({required this._remoteDataService});

  final RemoteDataService _remoteDataService;

  @override
  Future<Result<ReceivedNotifications?>> getReceived() async {
    final fid = PushNotifications.fid;
    if (fid == null) return const Result.ok(null);

    try {
      final received = await _remoteDataService.getReceivedNotifications(fid);
      PushNotifications.unread.value = received.unread; // The badge follows what's shown
      return Result.ok(received);
    } on Exception catch (error) {
      return Result.error(error);
    }
  }

  @override
  Future<Result<void>> markAllRead() async {
    final fid = PushNotifications.fid;
    if (fid == null) return const Result.ok(null);

    try {
      await _remoteDataService.markNotificationsRead(fid);
      PushNotifications.unread.value = 0;
      return const Result.ok(null);
    } on Exception catch (error) {
      return Result.error(error);
    }
  }
}
