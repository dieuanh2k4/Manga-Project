import '../repositories/notification_repository.dart';

class CountUnreadNotificationUseCase {
  final NotificationRepository repository;

  CountUnreadNotificationUseCase(this.repository);

  Future<int> call(String token) {
    return repository.countUnreadNotification(token);
  }
}
