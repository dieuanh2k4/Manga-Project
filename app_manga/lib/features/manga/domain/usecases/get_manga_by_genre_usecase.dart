import '../entities/manga_entity.dart';
import '../repositories/manga_repository.dart';

class GetMangaByGenreUseCase {
  final MangaRepository repository;

  GetMangaByGenreUseCase(this.repository);

  Future<List<MangaEntity>> call(int genreId) {
    return repository.getMangaByGenre(genreId);
  }
}
