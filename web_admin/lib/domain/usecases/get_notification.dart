import 'package:web_admin/core/resources/data_state.dart';
import 'package:web_admin/core/usecase/usecase.dart';
import 'package:web_admin/domain/entities/notification.dart';
import 'package:web_admin/domain/repository/notification_repository.dart';

class GetNotificationUseCase
    implements UseCase<DataState<List<NotificationEntity>>, void> {
  final NotificationRepository _notificationRepository;

  GetNotificationUseCase(this._notificationRepository);

  @override
  Future<DataState<List<NotificationEntity>>> call({void params}) {
    return _notificationRepository.getNotification();
  }
}
