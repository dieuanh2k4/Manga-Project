import '../../../manga/domain/entities/manga_entity.dart';

class LibraryMangaEntity extends MangaEntity {
  const LibraryMangaEntity({
    required super.id,
    required super.title,
    super.description,
    super.thumbnail,
    required super.totalChapter,
    required super.rate,
    super.status,
    super.genres,
  });
}
