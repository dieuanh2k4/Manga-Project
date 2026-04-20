import '../entities/manga_entity.dart';
import '../repositories/manga_repository.dart';

class GetMangaDetailUseCase {
  final MangaRepository repository;

  GetMangaDetailUseCase(this.repository);

  Future<MangaEntity> call(int mangaId) {
    return repository.getMangaDetail(mangaId);
  }
}
