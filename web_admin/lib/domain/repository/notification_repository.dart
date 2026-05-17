import 'package:web_admin/core/resources/data_state.dart';
import 'package:web_admin/domain/entities/notification.dart';

abstract class NotificationRepository {
  Future<DataState<List<NotificationEntity>>> getNotification();

  Future<DataState<bool>> createNotification(
    NotificationEntity notification,
  );
}
