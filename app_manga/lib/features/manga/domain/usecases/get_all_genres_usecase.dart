import '../entities/genre_entity.dart';
import '../repositories/manga_repository.dart';

class GetAllGenresUseCase {
  final MangaRepository repository;

  GetAllGenresUseCase(this.repository);

  Future<List<GenreEntity>> call() {
    return repository.getAllGenres();
  }
}
