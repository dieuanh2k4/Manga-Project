import '../entities/chapter_entity.dart';
import '../repositories/manga_repository.dart';

class GetChaptersByMangaUseCase {
  final MangaRepository repository;

  GetChaptersByMangaUseCase(this.repository);

  Future<List<ChapterEntity>> call(int mangaId) {
    return repository.getChaptersByManga(mangaId);
  }
}
