import '../entities/notification_entity.dart';

abstract class NotificationRepository {
  Future<List<NotificationEntity>> getNotificationByReaderId(String token);
  Future<int> countUnreadNotification(String token);
  Future<void> markNotificationAsRead(int notificationId, String token);
  Future<void> markAllUnreadNotifications(String token);
}
