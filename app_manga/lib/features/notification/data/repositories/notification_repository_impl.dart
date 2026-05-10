import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_data_source.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;

  NotificationRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<NotificationEntity>> getNotificationByReaderId(String token) async {
    final models = await remoteDataSource.getNotificationByReaderId(token);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<int> countUnreadNotification(String token) {
    return remoteDataSource.countUnreadNotification(token);
  }

  @override
  Future<void> markNotificationAsRead(int notificationId, String token) {
    return remoteDataSource.markNotificationAsRead(notificationId, token);
  }

  @override
  Future<void> markAllUnreadNotifications(String token) {
    return remoteDataSource.markAllUnreadNotifications(token);
  }
}
