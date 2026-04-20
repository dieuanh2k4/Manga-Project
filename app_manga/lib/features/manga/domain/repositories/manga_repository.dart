import '../entities/chapter_entity.dart';
import '../entities/genre_entity.dart';
import '../entities/manga_entity.dart';

abstract class MangaRepository {
  Future<List<MangaEntity>> getAllManga();
  Future<List<MangaEntity>> searchManga(String query);
  Future<List<MangaEntity>> getOngoingManga();
  Future<List<MangaEntity>> getCompletedManga();
  Future<List<MangaEntity>> getMangaByGenre(int genreId);
  Future<List<GenreEntity>> getAllGenres();
  Future<MangaEntity> getMangaDetail(int mangaId);
  Future<List<ChapterEntity>> getChaptersByManga(int mangaId);
}
