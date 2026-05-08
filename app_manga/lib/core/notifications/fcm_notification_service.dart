import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FcmNotificationService {
  FcmNotificationService._();

  static final FcmNotificationService instance = FcmNotificationService._();

  bool _isInitialized = false;
  bool _isMessagingAvailable = false;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    try {
      await Firebase.initializeApp();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Firebase initialization skipped: $e');
      return;
    }

    if (!_supportsFirebaseMessaging) {
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;

      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      await messaging.subscribeToTopic('all');

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint(
          'Foreground FCM message: ${message.notification?.title ?? message.messageId}',
        );
      });

      _isMessagingAvailable = true;
    } catch (e) {
      debugPrint('Firebase Messaging initialization skipped: $e');
    }
  }

  Future<void> subscribeToAllReaders() async {
    if (!_isMessagingAvailable) {
      return;
    }

    await FirebaseMessaging.instance.subscribeToTopic('all');
  }

  Future<void> subscribeToManga(int mangaId) async {
    if (!_isMessagingAvailable || mangaId <= 0) {
      return;
    }

    await FirebaseMessaging.instance.subscribeToTopic(_mangaTopic(mangaId));
  }

  Future<void> unsubscribeFromManga(int mangaId) async {
    if (!_isMessagingAvailable || mangaId <= 0) {
      return;
    }

    await FirebaseMessaging.instance.unsubscribeFromTopic(_mangaTopic(mangaId));
  }

  Future<void> syncMangaTopics(Iterable<int> mangaIds) async {
    if (!_isMessagingAvailable) {
      return;
    }

    final uniqueIds = mangaIds.where((id) => id > 0).toSet();
    for (final mangaId in uniqueIds) {
      await subscribeToManga(mangaId);
    }
  }

  String _mangaTopic(int mangaId) => 'manga_$mangaId';

  bool get _supportsFirebaseMessaging {
    if (kIsWeb) {
      return false;
    }

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }
}
