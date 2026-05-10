import '../../domain/entities/notification_entity.dart';

class NotificationModel {
  final int id;
  final String title;
  final String content;
  final String? targetRole;
  final int mangaId;
  final DateTime createdAt;
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.content,
    this.targetRole,
    required this.mangaId,
    required this.createdAt,
    required this.isRead,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final notificationJson = json['notification'] ?? json['Notification'];
    final source = notificationJson is Map<String, dynamic> ? notificationJson : json;
    final notificationReadJson =
        json['notificationRead'] ?? json['NotificationRead'];
    final readSource =
        notificationReadJson is Map<String, dynamic> ? notificationReadJson : json;
    final createdAtValue =
        source['createdAt'] ?? source['CreatedAt'] ?? json['readAt'] ?? json['ReadAt'];
    final rawIsRead =
        json['isRead'] ?? json['IsRead'] ?? source['isRead'] ?? source['IsRead'] ??
            readSource['isRead'] ?? readSource['IsRead'];

    return NotificationModel(
      id: source['id'] ??
          source['Id'] ??
          source['notificationId'] ??
          source['NotificationId'] ??
          source['NotificationID'] ??
          json['notificationId'] ??
          json['NotificationId'] ??
          json['NotificationID'] ??
          0,
      title: (source['title'] ?? source['Title'] ?? 'Thong bao').toString(),
      content: (source['content'] ?? source['Content'] ?? source['body'] ?? source['Body'] ?? '').toString(),
      targetRole: (source['targetRole'] ?? source['TargetRole'])?.toString(),
      mangaId: source['mangaId'] ??
          source['MangaId'] ??
          source['MangaID'] ??
          json['mangaId'] ??
          json['MangaId'] ??
          json['MangaID'] ??
          0,
      createdAt: DateTime.tryParse(createdAtValue?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      isRead: rawIsRead is bool
          ? rawIsRead
          : rawIsRead?.toString().toLowerCase() == 'true',
    );
  }

  NotificationEntity toEntity() {
    return NotificationEntity(
      id: id,
      title: title,
      content: content,
      targetRole: targetRole,
      mangaId: mangaId,
      createdAt: createdAt,
      isRead: isRead,
    );
  }
}
