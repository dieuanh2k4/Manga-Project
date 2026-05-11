import '../repositories/notification_repository.dart';

class MarkNotificationAsReadUseCase {
  final NotificationRepository repository;

  MarkNotificationAsReadUseCase(this.repository);

  Future<void> call(int notificationId, String token) {
    return repository.markNotificationAsRead(notificationId, token);
  }
}
