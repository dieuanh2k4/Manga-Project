import '../repositories/library_repository.dart';

class AddMangaToLibraryUseCase {
  final LibraryRepository repository;
  AddMangaToLibraryUseCase(this.repository);
  Future<void> call(int mangaId, String token) => repository.addMangaToLibrary(mangaId, token);
}
