import '../entities/manga_entity.dart';
import '../repositories/manga_repository.dart';

class GetCompletedMangaUseCase {
  final MangaRepository repository;

  GetCompletedMangaUseCase(this.repository);

  Future<List<MangaEntity>> call() {
    return repository.getCompletedManga();
  }
}
