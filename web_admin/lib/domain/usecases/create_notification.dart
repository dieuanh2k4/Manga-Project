import 'package:dio/dio.dart';
import 'package:web_admin/core/resources/data_state.dart';
import 'package:web_admin/core/usecase/usecase.dart';
import 'package:web_admin/domain/entities/notification.dart';
import 'package:web_admin/domain/repository/notification_repository.dart';

class CreateNotificationUseCase
    implements UseCase<DataState<bool>, NotificationEntity?> {
  final NotificationRepository _notificationRepository;

  CreateNotificationUseCase(this._notificationRepository);

  @override
  Future<DataState<bool>> call({NotificationEntity? params}) {
    if (params == null) {
      return Future<DataState<bool>>.value(
        DataFailed(
          DioError(
            error: 'Thieu du lieu tao notification',
            requestOptions: RequestOptions(
              path: 'FcmNotification/create-notification',
            ),
            type: DioErrorType.other,
          ),
        ),
      );
    }

    return _notificationRepository.createNotification(params);
  }
}
