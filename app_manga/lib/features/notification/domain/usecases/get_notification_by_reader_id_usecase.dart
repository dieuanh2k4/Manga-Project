import '../entities/notification_entity.dart';
import '../repositories/notification_repository.dart';

class GetNotificationByReaderIdUseCase {
  final NotificationRepository repository;

  GetNotificationByReaderIdUseCase(this.repository);

  Future<List<NotificationEntity>> call(String token) {
    return repository.getNotificationByReaderId(token);
  }
}
