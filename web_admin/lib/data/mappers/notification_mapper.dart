import 'package:web_admin/data/models/notification_model.dart';
import 'package:web_admin/domain/entities/notification.dart';

extension NotificationModelMapper on NotificationModel {
  NotificationEntity toEntity() {
    return NotificationEntity(
      id: id,
      title: title,
      content: content,
      targetRole: targetRole,
      mangaId: mangaId,
      createAt: createAt,
      isRead: isRead,
    );
  }
}

extension NotificationEntityMapper on NotificationEntity {
  NotificationModel toModel() {
    return NotificationModel(
      id: id,
      title: title,
      content: content,
      targetRole: targetRole,
      mangaId: mangaId,
      createAt: createAt,
      isRead: isRead,
    );
  }
}

extension NotificationModelListMapper on List<NotificationModel> {
  List<NotificationEntity> toEntityList() {
    return map((notificationModel) => notificationModel.toEntity()).toList();
  }
}

extension NotificationEntityListMapper on List<NotificationEntity> {
  List<NotificationModel> toModelList() {
    return map((notificationEntity) => notificationEntity.toModel()).toList();
  }
}
