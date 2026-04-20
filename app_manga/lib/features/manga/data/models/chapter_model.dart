import '../../domain/entities/chapter_entity.dart';

class ChapterModel {
  final int id;
  final String chapterNumber;
  final String title;
  final bool isPremium;

  const ChapterModel({
    required this.id,
    required this.chapterNumber,
    required this.title,
    required this.isPremium,
  });

  factory ChapterModel.fromJson(Map<String, dynamic> json) {
    final rawChapter = json['chapterNumber'] ?? json['ChapterNumber'] ?? '';
    final rawTitle = json['title'] ?? json['Title'] ?? '';

    return ChapterModel(
      id: json['id'] ?? json['Id'] ?? 0,
      chapterNumber: rawChapter.toString(),
      title: rawTitle.toString(),
      isPremium: json['isPremium'] ?? json['IsPremium'] ?? false,
    );
  }

  ChapterEntity toEntity() {
    return ChapterEntity(
      id: id,
      chapterNumber: chapterNumber,
      title: title,
      isPremium: isPremium,
    );
  }
}
