import '../repositories/manga_repository.dart';

class UpsertHistoryUseCase {
  final MangaRepository repository;
  UpsertHistoryUseCase(this.repository);

  Future<void> call({
    required int mangaId,
    required int chapterId,
    required int pageId,
    required String token,
    bool? isCompleted,
  }) {
    return repository.upsertHistory(
      mangaId: mangaId,
      chapterId: chapterId,
      pageId: pageId,
      token: token,
      isCompleted: isCompleted,
    );
  }
}
