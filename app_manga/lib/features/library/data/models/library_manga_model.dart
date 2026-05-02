import '../../../manga/data/models/manga_model.dart';

class LibraryMangaModel extends MangaModel {
  const LibraryMangaModel({
    required super.id,
    required super.title,
    super.description,
    super.thumbnail,
    required super.totalChapter,
    required super.rate,
    super.status,
    super.genres,
  });

  factory LibraryMangaModel.fromJson(Map<String, dynamic> json) {
    return LibraryMangaModel(
      id: json['id'] ?? json['Id'] ?? 0,
      title: json['title'] ?? json['Title'] ?? 'Unknown Title',
      description: json['description'] ?? json['Description'],
      thumbnail: json['thumbnail'] ?? json['Thumbnail'],
      totalChapter: json['totalChapter'] ?? json['TotalChapter'] ?? 0,
      rate: json['rate'] ?? json['Rate'] ?? 0,
      status: json['status'] ?? json['Status'],
      genres: [], // genres có thể bổ sung nếu backend trả về
    );
  }
}
