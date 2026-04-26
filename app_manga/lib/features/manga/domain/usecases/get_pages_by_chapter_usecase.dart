import '../entities/chapter_page_entity.dart';
import '../repositories/manga_repository.dart';

class GetPagesByChapterUseCase {
  final MangaRepository repository;

  GetPagesByChapterUseCase(this.repository);

  Future<List<ChapterPageEntity>> call({
    required int mangaId,
    required int chapterId,
    String? token,
  }) {
    return repository.getPagesByChapter(
      mangaId: mangaId,
      chapterId: chapterId,
      token: token,
    );
  }
}
