import 'package:flutter/material.dart';

import '../../domain/entities/notification_entity.dart';
import '../../domain/usecases/count_unread_notification_usecase.dart';
import '../../domain/usecases/get_notification_by_reader_id_usecase.dart';
import '../../domain/usecases/mark_all_unread_notifications_usecase.dart';
import '../../domain/usecases/mark_notification_as_read_usecase.dart';

class NotificationController extends ChangeNotifier {
  final GetNotificationByReaderIdUseCase getNotificationByReaderIdUseCase;
  final CountUnreadNotificationUseCase countUnreadNotificationUseCase;
  final MarkNotificationAsReadUseCase markNotificationAsReadUseCase;
  final MarkAllUnreadNotificationsUseCase markAllUnreadNotificationsUseCase;

  NotificationController({
    required this.getNotificationByReaderIdUseCase,
    required this.countUnreadNotificationUseCase,
    required this.markNotificationAsReadUseCase,
    required this.markAllUnreadNotificationsUseCase,
  });

  List<NotificationEntity> notifications = [];
  int unreadCount = 0;
  bool isLoading = false;
  String? error;

  Future<void> fetchNotifications(String token) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      notifications = await getNotificationByReaderIdUseCase(token);
      unreadCount = notifications.where((notification) => !notification.isRead).length;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUnreadCount(String token) async {
    try {
      unreadCount = await countUnreadNotificationUseCase(token);
      notifyListeners();
    } catch (_) {
      // The badge should not block the home page.
    }
  }

  Future<void> markAsRead({
    required int notificationId,
    required String token,
  }) async {
    await markNotificationAsReadUseCase(notificationId, token);
    _markLocalAsRead(notificationId);
  }

  Future<void> markAllAsRead(String token) async {
    if (unreadCount == 0) {
      return;
    }

    await markAllUnreadNotificationsUseCase(token);
    notifications = notifications
        .map(
          (notification) => NotificationEntity(
            id: notification.id,
            title: notification.title,
            content: notification.content,
            targetRole: notification.targetRole,
            mangaId: notification.mangaId,
            createdAt: notification.createdAt,
            isRead: true,
          ),
        )
        .toList();
    unreadCount = 0;
    notifyListeners();
  }

  void _markLocalAsRead(int notificationId) {
    notifications = notifications
        .map(
          (notification) => notification.id == notificationId
              ? NotificationEntity(
                  id: notification.id,
                  title: notification.title,
                  content: notification.content,
                  targetRole: notification.targetRole,
                  mangaId: notification.mangaId,
                  createdAt: notification.createdAt,
                  isRead: true,
                )
              : notification,
        )
        .toList();
    unreadCount = notifications.where((notification) => !notification.isRead).length;
    notifyListeners();
  }
}
