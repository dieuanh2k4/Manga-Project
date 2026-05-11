import 'package:dio/dio.dart';
import 'package:web_admin/core/resources/data_state.dart';
import 'package:web_admin/data/data_sources/remote/notification_api_service.dart';
import 'package:web_admin/data/mappers/notification_mapper.dart';
import 'package:web_admin/domain/entities/notification.dart';
import 'package:web_admin/domain/repository/notification_repository.dart';

class NotificationReposityImpl implements NotificationRepository {
  final NotificationApiService _notificationApiService;

  NotificationReposityImpl(this._notificationApiService);

  @override
  Future<DataState<List<NotificationEntity>>> getNotification() async {
    try {
      final notification = await _notificationApiService.getAllNotification();

      return DataSuccess(notification.toEntityList());
    } on DioError catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<bool>> createNotification(
    NotificationEntity notification,
  ) async {
    try {
      final Response<dynamic> response = await _notificationApiService
          .createNotification(notification.toModel());

      if (response.statusCode == 200 || response.statusCode == 201) {
        return const DataSuccess(true);
      }

      return DataFailed(
        DioError(
          error: response.statusMessage,
          response: response,
          requestOptions: response.requestOptions,
          type: DioErrorType.response,
        ),
      );
    } on DioError catch (e) {
      return DataFailed(e);
    }
  }
}
