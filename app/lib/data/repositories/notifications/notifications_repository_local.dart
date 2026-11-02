// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/notifications/notifications_repository.dart';
import 'package:app/domain/models/notification/received_notification.dart';
import 'package:app/utils/result.dart';

/// Local data has no notifications: they come from the API.
class NotificationsRepositoryLocal implements NotificationsRepository {
  @override
  Future<Result<ReceivedNotifications?>> getReceived() async => const Result.ok(null);

  @override
  Future<Result<void>> markAllRead() async => const Result.ok(null);
}
