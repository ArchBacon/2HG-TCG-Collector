// Copyright 2026 Christian Delicaat. All rights reserved.

/// What a received notification was about, for its icon.
enum NotificationKind {
  wishlist,
  announcement,
  test;

  static NotificationKind fromApi(String type) => switch (type) {
    'announcement' => announcement,
    'test' => test,
    _ => wishlist,
  };
}

/// A notification this device received, as the API recorded it when sending.
class ReceivedNotification {
  final int id;
  final NotificationKind kind;
  final String title;
  final String body;

  /// The page it opens, e.g. '/wishlist'; null for none.
  final String? route;
  final DateTime sentAt;
  final bool read;

  const ReceivedNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.route,
    required this.sentAt,
    required this.read,
  });

  factory ReceivedNotification.fromJson(Map<String, dynamic> json) => ReceivedNotification(
    id: json['id'] as int,
    kind: NotificationKind.fromApi(json['type'] as String),
    title: json['title'] as String,
    body: json['body'] as String,
    route: json['route'] as String?,
    sentAt: DateTime.parse(json['sentAt'] as String).toLocal(),
    read: json['read'] as bool,
  );
}

/// This device's received notifications, newest first, and how many are unread.
class ReceivedNotifications {
  final int unread;
  final List<ReceivedNotification> notifications;

  const ReceivedNotifications({required this.unread, required this.notifications});
}
