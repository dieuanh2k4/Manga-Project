import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FcmNotificationService {
  FcmNotificationService._();

  static final FcmNotificationService instance = FcmNotificationService._();
  // chanel này dùng khi app đang mở
  static const String _androidChannelId = 'manga_notifications'; // tên kĩ thuật
  // tên channel người dùng có thể thấy trong Androi Settings
  static const String _androidChannelName = 'Manga notifications';

  // tránh khởi tạo Firebase nhiều lần
  bool _isInitialized = false;
  // đánh dấu DCM dùng được chưa
  bool _isMessagingAvailable = false;

  // khi app mở và nhận FCM, service sẽ đẩy message vào stream này
  // Home Page đang nghe stream đó để refresh (unread count, danh sách notification)
  final _messageController = StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get foregroundMessages => _messageController.stream;

  // tự show notification khi app đang mở
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // gọi trong main khi khởi động
  // nếu đã init rồi thì return để tránh đăng ký listener nhiều lần
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    // khởi tạo Firebase, đọc firebase config: app_manga/android/app/google-services.json
    try {
      await Firebase.initializeApp();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Firebase initialization skipped: $e');
      return;
    }

    // kiểm tra platform có hỗ trợ FCM không
    // không chạy trên web, chỉ chạy trên androi, ios, macOS
    if (!_supportsFirebaseMessaging) {
      return;
    }

    try {
      // khởi tạo local notification
      await _initializeLocalNotifications();

      final messaging = FirebaseMessaging.instance;

      // xin quyền notification
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      // subcribe topic mặc định
      await messaging.subscribeToTopic('all');

      // nghe fcm khi app foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        // phát sự kiện cho UI, HomePage nghe sự kiện này để refresh unread count/list noti
        _messageController.add(message);
        // tự hiện notification local
        _showForegroundNotification(message);
      });

      // đánh dấu fcm sẵn sàng
      _isMessagingAvailable = true;
    } catch (e) {
      debugPrint('Firebase Messaging initialization skipped: $e');
    }
  }

  // khởi tạo phần thông báo local trên androi
  // trước khi app bắt đầu nhận và tự hiện thị thống báo fcm ở foreground
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(settings: initializationSettings);

    const androidChannel = AndroidNotificationChannel(
      _androidChannelId,
      _androidChannelName,
      description: 'Notifications for new manga updates and announcements.',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

  // tự hiển thị thông báo cục bộ khi app đang mở và nhận được một fcm message
  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title']?.toString();
    final body = notification?.body ?? message.data['body']?.toString();

    if (title == null && body == null) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      _androidChannelId,
      _androidChannelName,
      channelDescription:
          'Notifications for new manga updates and announcements.',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: message.data['mangaId']?.toString(),
    );
  }

  // Đăng ký topic chung để nhận thông báo dành cho toàn bộ người đọc.
  Future<void> subscribeToAllReaders() async {
    if (!_isMessagingAvailable) {
      return;
    }

    await FirebaseMessaging.instance.subscribeToTopic('all');
  }

  // Đăng ký topic riêng của một manga để nhận thông báo đúng nội dung đã theo dõi.
  Future<void> subscribeToManga(int mangaId) async {
    if (!_isMessagingAvailable || mangaId <= 0) {
      return;
    }

    await FirebaseMessaging.instance.subscribeToTopic(_mangaTopic(mangaId));
  }

  // Hủy đăng ký topic của manga khi người dùng không còn theo dõi nữa.
  Future<void> unsubscribeFromManga(int mangaId) async {
    if (!_isMessagingAvailable || mangaId <= 0) {
      return;
    }

    await FirebaseMessaging.instance.unsubscribeFromTopic(_mangaTopic(mangaId));
  }

  // Đồng bộ toàn bộ topic manga hợp lệ để tránh bị thiếu đăng ký sau khi mở app.
  Future<void> syncMangaTopics(Iterable<int> mangaIds) async {
    if (!_isMessagingAvailable) {
      return;
    }

    final uniqueIds = mangaIds.where((id) => id > 0).toSet();
    for (final mangaId in uniqueIds) {
      await subscribeToManga(mangaId);
    }
  }

  // Tạo tên topic theo format cố định cho từng manga.
  String _mangaTopic(int mangaId) => 'manga_$mangaId';

  // Chỉ bật FCM trên các nền tảng được hỗ trợ; web thì không dùng ở service này.
  bool get _supportsFirebaseMessaging {
    if (kIsWeb) {
      return false;
    }

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }
}
