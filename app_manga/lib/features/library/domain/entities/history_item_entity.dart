class HistoryItemEntity {
  final int mangaId;
  final int lastChapterId;
  final int lastPageId;
  final bool isCompleted;
  final DateTime updatedAt;
  final String title;
  final String? thumbnail;
  final String? authorName;

  const HistoryItemEntity({
    required this.mangaId,
    required this.lastChapterId,
    required this.lastPageId,
    required this.isCompleted,
    required this.updatedAt,
    required this.title,
    this.thumbnail,
    this.authorName,
  });
}
