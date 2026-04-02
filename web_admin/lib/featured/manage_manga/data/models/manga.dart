import 'package:web_admin/featured/manage_manga/domain/entities/manga.dart';

class MangaModel extends MangaEntity {
  const MangaModel({
    int? id,
    String? title,
    String? description,
    String? thumbnail,
    String? status,
    String? totalChapter,
    int? rate,
    int? authorid,
    List<int>? genreIds,
    DateTime? releaseDate,
    DateTime? endDate,
  });

  factory MangaModel.fromJson(Map<String, dynamic> map) {
    return MangaModel(
      title: map['title'] ?? "",
      description: map['description'] ?? "",
      thumbnail: map['thumbnail'] ?? "",
      status: map['status'] ?? "",
      totalChapter: map['totalChapter'] ?? "",
      rate: map['rate'] ?? "",
      authorid: map['authorid'] ?? "",
      genreIds: map['genreIds'] ?? "",
      releaseDate: map['releaseDate'] ?? "",
      endDate: map['endDate'] ?? "",
    );
  }
}
