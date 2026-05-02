import '../entities/library_manga_entity.dart';

abstract class LibraryRepository {
  Future<List<LibraryMangaEntity>> getLibraryManga(String token);
  Future<void> addMangaToLibrary(int mangaId, String token);
  Future<void> deleteMangaFromLibrary(int mangaId, String token);
}
