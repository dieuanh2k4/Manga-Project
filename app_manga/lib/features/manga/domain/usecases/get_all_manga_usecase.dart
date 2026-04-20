import '../entities/manga_entity.dart';
import '../repositories/manga_repository.dart';

class GetAllMangaUseCase {
  final MangaRepository repository;

  GetAllMangaUseCase(this.repository);

  Future<List<MangaEntity>> call() {
    return repository.getAllManga();
  }
}
