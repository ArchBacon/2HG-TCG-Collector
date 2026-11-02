// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/domain/models/notification/received_notification.dart';
import 'package:app/utils/result.dart';

/// The notifications this device received (kept by the API), and their read state.
abstract class NotificationsRepository {
  /// Newest first, with the unread count. Null when this device isn't set up for notifications
  /// (no Firebase, not registered yet, or the development flavor's local data).
  Future<Result<ReceivedNotifications?>> getReceived();

  /// Marks them all read; the unread badge goes to 0.
  Future<Result<void>> markAllRead();
}
