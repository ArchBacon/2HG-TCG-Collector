// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/notifications/notifications_repository.dart';
import 'package:app/domain/models/notification/received_notification.dart';
import 'package:app/utils/command.dart';
import 'package:app/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// The notifications this device received, newest first, and marking them all read.
class NotificationsViewModel extends ChangeNotifier {
  NotificationsViewModel({required this._repository}) {
    load = Command0(_load)..execute();
    markAllRead = Command0(_markAllRead);
  }

  final NotificationsRepository _repository;
  final _log = Logger('NotificationsViewModel');

  late final Command0<ReceivedNotifications?> load;
  late final Command0<void> markAllRead;

  ReceivedNotifications? _received;
  var _setUp = true;

  /// Null before the first load, and when it failed.
  List<ReceivedNotification>? get notifications => _received?.notifications;

  int get unread => _received?.unread ?? 0;

  /// False when this device isn't set up for notifications (see NotificationsRepository).
  bool get setUp => _setUp;

  Future<Result<ReceivedNotifications?>> _load() async {
    final result = await _repository.getReceived();
    switch (result) {
      case Ok(:final value):
        _received = value ?? const ReceivedNotifications(unread: 0, notifications: []);
        _setUp = value != null;
      case Error(:final error):
        _log.warning('Failed to load the notifications', error);
    }
    notifyListeners();
    return result;
  }

  Future<Result<void>> _markAllRead() async {
    final result = await _repository.markAllRead();
    switch (result) {
      case Ok():
        final received = _received;
        if (received != null) {
          _received = ReceivedNotifications(
            unread: 0,
            notifications: [
              for (final n in received.notifications)
                ReceivedNotification(
                  id: n.id,
                  kind: n.kind,
                  title: n.title,
                  body: n.body,
                  route: n.route,
                  sentAt: n.sentAt,
                  read: true,
                ),
            ],
          );
        }
      case Error(:final error):
        _log.warning('Failed to mark the notifications read', error);
    }
    notifyListeners();
    return result;
  }
}
