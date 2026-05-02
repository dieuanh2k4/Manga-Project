import '../../domain/entities/library_manga_entity.dart';
import '../../domain/repositories/library_repository.dart';
import '../datasources/library_remote_data_source.dart';
import '../models/library_manga_model.dart';

class LibraryRepositoryImpl implements LibraryRepository {
  final LibraryRemoteDataSource remoteDataSource;
  LibraryRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<LibraryMangaEntity>> getLibraryManga(String token) async {
    final models = await remoteDataSource.getLibraryManga(token);
    return models.map((e) => LibraryMangaEntity(
      id: e.id,
      title: e.title,
      description: e.description,
      thumbnail: e.thumbnail,
      totalChapter: e.totalChapter,
      rate: e.rate,
      status: e.status,
      genres: e.genres.map((g) => g.toEntity()).toList(),
    )).toList();
  }

  @override
  Future<void> addMangaToLibrary(int mangaId, String token) {
    return remoteDataSource.addMangaToLibrary(mangaId, token);
  }

  @override
  Future<void> deleteMangaFromLibrary(int mangaId, String token) {
    return remoteDataSource.deleteMangaFromLibrary(mangaId, token);
  }
}
