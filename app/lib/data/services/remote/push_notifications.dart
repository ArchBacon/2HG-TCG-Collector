// Copyright 2026 Christian Delicaat. All rights reserved.

import 'dart:async';
import 'dart:io';

import 'package:app/data/services/local/remote_data_service.dart';
import 'package:app/data/services/remote/user_token.dart';
import 'package:app/firebase_options.dart';
import 'package:app/ui/shared/app_state.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';

/// Push notifications with Firebase Cloud Messaging, in the production flavor only. The API sends
/// them (cards on the wishlist that came into stock) to this device's Firebase Installation ID
/// (FID). This registers the FID with the API, as the current user: when Firebase gives one (on
/// start, or a new one), when the user changes (a redeemed sync code) and when the switch in the
/// settings changes.
///
/// Firebase's setup is in `lib/firebase_options.dart` and `android/app/google-services.json`
/// (project hg-collector), from `flutterfire configure`.
abstract final class PushNotifications {
  static final _log = Logger('PushNotifications');

  /// The page a tapped notification asks for (e.g. '/wishlist'); MainApp opens it and clears it.
  static final openedRoute = ValueNotifier<String?>(null);

  /// A notification that arrived while the app is open, for NotificationBanner to show (the system
  /// shows nothing then); it clears it once taken.
  static final inApp = ValueNotifier<InAppNotification?>(null);

  /// How many of this device's received notifications are unread, for the badge on the Settings
  /// tab. From the API ([refreshUnread]); a notification that arrives counts right away.
  static final unread = ValueNotifier(0);

  /// This device's FID, once Firebase gave it: what the API knows it by.
  static String? get fid => _fid;
  static String? _fid;

  /// The API's record of a send can lag the notification itself by a moment.
  static const _recordDelay = Duration(seconds: 3);


  /// Sets Firebase up and starts registering. Call before runApp, after AppPreferences.load and
  /// UserToken.loadOrCreate. Without Firebase (setup missing) the app runs without notifications.
  static Future<void> start() async {
    try {
      // Android: google-services.json, which has the Firebase app of each flavor's package. iOS has
      // no GoogleService-Info.plist yet (flutterfire can't add it on Windows): the generated options.
      await Firebase.initializeApp(options: Platform.isIOS ? DefaultFirebaseOptions.currentPlatform : null);
    } catch (error) {
      _log.warning('Firebase could not be set up; no notifications', error);
      return;
    }

    final messaging = FirebaseMessaging.instance;
    // While the app is open: our own banner (NotificationBanner), on both platforms; iOS would
    // otherwise show its own too
    await messaging.setForegroundNotificationPresentationOptions(alert: false, badge: true, sound: true);
    FirebaseMessaging.onMessage.listen(_showInApp);

    // Tapped while the app ran in the background, or started the app
    FirebaseMessaging.onMessageOpenedApp.listen(_open);
    final initial = await messaging.getInitialMessage();
    if (initial != null) _open(initial);

    messaging.onRegistered.listen((fid) {
      _fid = fid;
      unawaited(_sendToApi());
    });
    UserToken.current.addListener(_sendToApi);
    for (final setting in [wishlistNotifications, newsNotifications]) {
      setting.addListener(() async {
        if (setting.value) await _askPermission();
        await _sendToApi();
      });
    }

    // The unread count, current again when the app comes back to the foreground (the binding keeps it)
    AppLifecycleListener(onResume: refreshUnread);

    if (wishlistNotifications.value || newsNotifications.value) await _askPermission();
    unawaited(messaging.register().catchError((Object error) => _log.warning('Registering with Firebase failed', error)));
  }

  /// Gets the unread count from the API. Without a FID or user (not registered yet, offline, the
  /// development flavor) it stays as it is.
  static Future<void> refreshUnread() async {
    final fid = _fid;
    final apiToken = UserToken.current.value;
    if (fid == null || apiToken == null) return;

    try {
      unread.value = (await RemoteDataService(token: apiToken).getReceivedNotifications(fid)).unread;
    } catch (error) {
      _log.warning('Getting the unread notifications failed', error);
    }
  }

  static void _open(RemoteMessage message) {
    final route = _route(message);
    if (route != null) openedRoute.value = route;
    unawaited(Future.delayed(_recordDelay, refreshUnread));
  }

  static void _showInApp(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return; // Data only: nothing to show

    // Counts right away; the API's count replaces it once it has recorded the send
    unread.value++;
    unawaited(Future.delayed(_recordDelay, refreshUnread));

    inApp.value = InAppNotification(
      title: notification.title ?? '',
      body: notification.body ?? '',
      route: _route(message),
      isAnnouncement: message.data['type'] == 'announcement',
    );
  }

  static String? _route(RemoteMessage message) {
    final route = message.data['route'];
    return route is String && route.startsWith('/') ? route : null;
  }

  /// Asks to show notifications (Android 13+, iOS). The system asks only once and remembers.
  static Future<void> _askPermission() async {
    try {
      await FirebaseMessaging.instance.requestPermission();
    } catch (error) {
      _log.warning('Asking for notification permission failed', error);
    }
  }

  /// Tells the API this device's FID and switch, as the current user.
  static Future<void> _sendToApi() async {
    final fid = _fid;
    final apiToken = UserToken.current.value;
    // No FID yet: onRegistered sends it. No user: the API couldn't be reached; the next start does.
    if (fid == null || apiToken == null) return;

    try {
      await RemoteDataService(token: apiToken).registerDevice(
        fid,
        platform: Platform.isIOS ? 'ios' : 'android',
        wishlistInStore: wishlistNotifications.value,
        announcements: newsNotifications.value,
      );
      await refreshUnread();
    } catch (error) {
      _log.warning('Registering for notifications with the API failed', error);
    }
  }
}

/// A notification received while the app is open, as NotificationBanner shows it.
class InAppNotification {
  final String title;
  final String body;

  /// The page it opens when tapped, e.g. '/wishlist'.
  final String? route;

  /// One of the shop's announcements (news and events), not a wishlist notification.
  final bool isAnnouncement;

  const InAppNotification({required this.title, required this.body, this.route, this.isAnnouncement = false});
}
