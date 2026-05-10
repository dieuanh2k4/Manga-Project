import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:web_admin/core/resources/data_state.dart';
import 'package:web_admin/domain/entities/notification.dart';
import 'package:web_admin/domain/usecases/create_notification.dart';
import 'package:web_admin/domain/usecases/get_notification.dart';

abstract class RemoteNotificationState {
  final List<NotificationEntity>? notifications;
  final DioError? error;

  const RemoteNotificationState({this.notifications, this.error});
}

class RemoteNotificationLoading extends RemoteNotificationState {
  const RemoteNotificationLoading();
}

class RemoteNotificationDone extends RemoteNotificationState {
  const RemoteNotificationDone(List<NotificationEntity> notifications)
    : super(notifications: notifications);
}

class RemoteNotificationError extends RemoteNotificationState {
  const RemoteNotificationError(DioError error) : super(error: error);
}

class RemoteNotificationController extends ChangeNotifier {
  final GetNotificationUseCase _getNotificationUseCase;
  final CreateNotificationUseCase _createNotificationUseCase;

  RemoteNotificationController(
    this._getNotificationUseCase,
    this._createNotificationUseCase,
  );

  RemoteNotificationState _state = const RemoteNotificationLoading();
  bool _hasLoaded = false;

  RemoteNotificationState get state => _state;
  bool get hasLoaded => _hasLoaded;

  Future<void> loadNotifications() async {
    _state = const RemoteNotificationLoading();
    notifyListeners();

    final DataState<List<NotificationEntity>> dataState =
        await _getNotificationUseCase();

    _hasLoaded = true;

    if (dataState is DataSuccess<List<NotificationEntity>> &&
        dataState.data != null) {
      _state = RemoteNotificationDone(dataState.data!);
      notifyListeners();
      return;
    }

    if (dataState is DataFailed<List<NotificationEntity>> &&
        dataState.error != null) {
      _state = RemoteNotificationError(dataState.error!);
      notifyListeners();
    }
  }

  Future<DataState<bool>> createNotification(
    NotificationEntity notification,
  ) async {
    final DataState<bool> result = await _createNotificationUseCase(
      params: notification,
    );

    if (result is DataSuccess<bool>) {
      await loadNotifications();
    }

    return result;
  }
}
