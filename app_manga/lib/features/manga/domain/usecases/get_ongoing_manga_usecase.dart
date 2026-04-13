import '../entities/manga_entity.dart';
import '../repositories/manga_repository.dart';

class GetOngoingMangaUseCase {
  final MangaRepository repository;

  GetOngoingMangaUseCase(this.repository);

  Future<List<MangaEntity>> call() {
    return repository.getOngoingManga();
  }
}
