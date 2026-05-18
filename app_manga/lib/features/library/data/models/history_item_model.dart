import '../../domain/entities/history_item_entity.dart';

class HistoryItemModel {
  final int mangaId;
  final int lastChapterId;
  final int lastPageId;
  final bool isCompleted;
  final DateTime updatedAt;
  final String title;
  final String? thumbnail;
  final String? authorName;

  const HistoryItemModel({
    required this.mangaId,
    required this.lastChapterId,
    required this.lastPageId,
    required this.isCompleted,
    required this.updatedAt,
    required this.title,
    this.thumbnail,
    this.authorName,
  });

  factory HistoryItemModel.fromJson(Map<String, dynamic> json) {
    final rawUpdatedAt = json['updateAt'] ?? json['UpdateAt'];
    final parsedUpdatedAt = DateTime.tryParse(rawUpdatedAt?.toString() ?? '');
    final updatedAt =
        parsedUpdatedAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

    final rawTitle = (json['mangaTitle'] ?? json['MangaTitle'] ?? '')
        .toString()
        .trim();

    return HistoryItemModel(
      mangaId: json['mangaId'] ?? json['MangaId'] ?? 0,
      lastChapterId: json['lastChapterId'] ?? json['LastChapterId'] ?? 0,
      lastPageId: json['lastPageId'] ?? json['LastPageId'] ?? 0,
      isCompleted: json['isCompleted'] ?? json['IsCompleted'] ?? false,
      updatedAt: updatedAt,
      title: rawTitle.isEmpty ? 'Unknown title' : rawTitle,
      thumbnail: (json['mangaThumbnail'] ?? json['MangaThumbnail'])?.toString(),
      authorName: (json['mangaAuthor'] ?? json['MangaAuthor'])?.toString(),
    );
  }

  HistoryItemEntity toEntity() => HistoryItemEntity(
    mangaId: mangaId,
    lastChapterId: lastChapterId,
    lastPageId: lastPageId,
    isCompleted: isCompleted,
    updatedAt: updatedAt,
    title: title,
    thumbnail: thumbnail,
    authorName: authorName,
  );
}
