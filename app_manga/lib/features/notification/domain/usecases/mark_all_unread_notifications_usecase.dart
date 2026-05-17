import '../repositories/notification_repository.dart';

class MarkAllUnreadNotificationsUseCase {
  final NotificationRepository repository;

  MarkAllUnreadNotificationsUseCase(this.repository);

  Future<void> call(String token) {
    return repository.markAllUnreadNotifications(token);
  }
}
