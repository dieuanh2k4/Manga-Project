import '../../domain/entities/chapter_entity.dart';
import '../../domain/entities/genre_entity.dart';
import '../../domain/entities/manga_entity.dart';
import '../../domain/repositories/manga_repository.dart';
import '../datasources/manga_remote_data_source.dart';

class MangaRepositoryImpl implements MangaRepository {
  final MangaRemoteDataSource remoteDataSource;

  MangaRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<MangaEntity>> getAllManga() async {
    final data = await remoteDataSource.getAllManga();
    return data.map((e) => e.toEntity()).toList();
  }

  @override
  Future<List<GenreEntity>> getAllGenres() async {
    final data = await remoteDataSource.getAllGenres();
    return data.map((e) => e.toEntity()).toList();
  }

  @override
  Future<List<MangaEntity>> getCompletedManga() async {
    final data = await remoteDataSource.getCompletedManga();
    return data.map((e) => e.toEntity()).toList();
  }

  @override
  Future<List<MangaEntity>> getMangaByGenre(int genreId) async {
    final data = await remoteDataSource.getMangaByGenre(genreId);
    return data.map((e) => e.toEntity()).toList();
  }

  @override
  Future<List<MangaEntity>> getOngoingManga() async {
    final data = await remoteDataSource.getOngoingManga();
    return data.map((e) => e.toEntity()).toList();
  }

  @override
  Future<List<MangaEntity>> searchManga(String query) async {
    final data = await remoteDataSource.searchManga(query);
    return data.map((e) => e.toEntity()).toList();
  }

  @override
  Future<MangaEntity> getMangaDetail(int mangaId) async {
    final data = await remoteDataSource.getMangaDetail(mangaId);
    return data.toEntity();
  }

  @override
  Future<List<ChapterEntity>> getChaptersByManga(int mangaId) async {
    final data = await remoteDataSource.getChaptersByManga(mangaId);
    return data.map((e) => e.toEntity()).toList();
  }
}
