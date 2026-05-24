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
    final rawManga = json['manga'] ?? json['Manga'];
    final source = rawManga is Map<String, dynamic> ? rawManga : json;

    final rawTitle = source['title'] ?? source['Title'] ?? 'Unknown Title';
    final title = rawTitle is String ? rawTitle.replaceAll('\n', ' ').trim() : 'Unknown Title';

    return LibraryMangaModel(
      id: source['id'] ?? source['Id'] ?? json['mangaId'] ?? json['MangaId'] ?? 0,
      title: title,
      description: source['description'] ?? source['Description'],
      thumbnail: source['thumbnail'] ?? source['Thumbnail'],
      totalChapter: source['totalChapter'] ?? source['TotalChapter'] ?? 0,
      rate: source['rate'] ?? source['Rate'] ?? 0,
      status: source['status'] ?? source['Status'],
      genres: [], // genres có thể bổ sung nếu backend trả về
    );
  }
}
