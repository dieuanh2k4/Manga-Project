class NotificationEntity {
  final int id;
  final String title;
  final String content;
  final String? targetRole;
  final int mangaId;
  final DateTime createdAt;
  final bool isRead;

  const NotificationEntity({
    required this.id,
    required this.title,
    required this.content,
    this.targetRole,
    required this.mangaId,
    required this.createdAt,
    required this.isRead,
  });
}
