import '../entities/manga_entity.dart';
import '../repositories/manga_repository.dart';

class SearchMangaUseCase {
  final MangaRepository repository;

  SearchMangaUseCase(this.repository);

  Future<List<MangaEntity>> call(String query) {
    return repository.searchManga(query);
  }
}
