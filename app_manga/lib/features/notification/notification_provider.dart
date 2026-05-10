import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/datasources/notification_remote_data_source.dart';
import 'data/repositories/notification_repository_impl.dart';
import 'domain/repositories/notification_repository.dart';
import 'domain/usecases/count_unread_notification_usecase.dart';
import 'domain/usecases/get_notification_by_reader_id_usecase.dart';
import 'domain/usecases/mark_all_unread_notifications_usecase.dart';
import 'domain/usecases/mark_notification_as_read_usecase.dart';
import 'presentation/controllers/notification_controller.dart';

class NotificationProviders extends StatelessWidget {
  final Widget child;

  const NotificationProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final remoteDataSource = NotificationRemoteDataSource();
    final repository = NotificationRepositoryImpl(remoteDataSource);

    return MultiProvider(
      providers: [
        Provider<NotificationRepository>.value(value: repository),
        Provider<GetNotificationByReaderIdUseCase>.value(
          value: GetNotificationByReaderIdUseCase(repository),
        ),
        Provider<CountUnreadNotificationUseCase>.value(
          value: CountUnreadNotificationUseCase(repository),
        ),
        Provider<MarkNotificationAsReadUseCase>.value(
          value: MarkNotificationAsReadUseCase(repository),
        ),
        Provider<MarkAllUnreadNotificationsUseCase>.value(
          value: MarkAllUnreadNotificationsUseCase(repository),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationController(
            getNotificationByReaderIdUseCase: GetNotificationByReaderIdUseCase(repository),
            countUnreadNotificationUseCase: CountUnreadNotificationUseCase(repository),
            markNotificationAsReadUseCase: MarkNotificationAsReadUseCase(repository),
            markAllUnreadNotificationsUseCase: MarkAllUnreadNotificationsUseCase(repository),
          ),
        ),
      ],
      child: child,
    );
  }
}
