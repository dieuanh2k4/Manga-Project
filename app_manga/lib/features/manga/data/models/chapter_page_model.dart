import '../../domain/entities/chapter_page_entity.dart';

class ChapterPageModel {
  final int id;
  final int chapterId;
  final int mangaId;
  final String imageUrl;

  const ChapterPageModel({
    required this.id,
    required this.chapterId,
    required this.mangaId,
    required this.imageUrl,
  });

  factory ChapterPageModel.fromJson(Map<String, dynamic> json) {
    return ChapterPageModel(
      id: json['id'] ?? json['Id'] ?? 0,
      chapterId: json['chapterId'] ?? json['ChapterId'] ?? 0,
      mangaId: json['mangaId'] ?? json['MangaId'] ?? 0,
      imageUrl: (json['imageUrl'] ?? json['ImageUrl'] ?? '').toString(),
    );
  }

  ChapterPageEntity toEntity() {
    return ChapterPageEntity(
      id: id,
      chapterId: chapterId,
      mangaId: mangaId,
      imageUrl: imageUrl,
    );
  }
}
