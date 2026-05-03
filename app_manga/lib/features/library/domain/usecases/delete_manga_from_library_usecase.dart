import '../repositories/library_repository.dart';

class DeleteMangaFromLibraryUseCase {
  final LibraryRepository repository;
  DeleteMangaFromLibraryUseCase(this.repository);
  Future<void> call(int mangaId, String token) => repository.deleteMangaFromLibrary(mangaId, token);
}
