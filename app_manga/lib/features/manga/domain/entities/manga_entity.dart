import 'genre_entity.dart';

class MangaEntity {
  final int id;
  final String title;
  final String? description;
  final String? thumbnail;
  final int totalChapter;
  final int rate;
  final String? status;
  final List<GenreEntity> genres;

  const MangaEntity({
    required this.id,
    required this.title,
    this.description,
    this.thumbnail,
    required this.totalChapter,
    required this.rate,
    this.status,
    this.genres = const [],
  });
}
