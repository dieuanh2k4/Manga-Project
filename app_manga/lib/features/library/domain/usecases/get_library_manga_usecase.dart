import '../entities/library_manga_entity.dart';
import '../repositories/library_repository.dart';

class GetLibraryMangaUseCase {
  final LibraryRepository repository;
  GetLibraryMangaUseCase(this.repository);
  Future<List<LibraryMangaEntity>> call(String token) => repository.getLibraryManga(token);
}
