import 'package:web_admin/core/models/upload_file_data.dart';
import 'package:web_admin/core/resources/data_state.dart';
import 'package:web_admin/domain/entities/author.dart';
import 'package:web_admin/domain/entities/genre.dart';
import 'package:web_admin/domain/entities/manga.dart';
import 'package:web_admin/domain/usecases/create_manga.dart';
import 'package:web_admin/domain/usecases/delete_manga.dart';
import 'package:web_admin/domain/usecases/get_authors.dart';
import 'package:web_admin/domain/usecases/get_genres.dart';
import 'package:web_admin/domain/usecases/update_manga.dart';
import 'package:web_admin/presentation/helper/manage_manga_helper.dart';

class ManageMangaService {
  final CreateMangaUseCase _createMangaUseCase;
  final DeleteMangaUseCase _deleteMangaUseCase;
  final GetAuthorsUseCase _getAuthorsUseCase;
  final GetGenresUseCase _getGenresUseCase;
  final UpdateMangaUseCase _updateMangaUseCase;

  const ManageMangaService(
    this._createMangaUseCase,
    this._deleteMangaUseCase,
    this._getAuthorsUseCase,
    this._getGenresUseCase,
    this._updateMangaUseCase,
  );

  Future<ManageMangaLookupResult> loadLookupData() async {
    try {
      final Future<DataState<List<AuthorEntity>>> authorsFuture =
          _getAuthorsUseCase();
      final Future<DataState<List<GenreEntity>>> genresFuture =
          _getGenresUseCase();

      final DataState<List<AuthorEntity>> authorState = await authorsFuture;
      final DataState<List<GenreEntity>> genreState = await genresFuture;

      final List<AuthorEntity> authors =
          authorState is DataSuccess<List<AuthorEntity>> &&
              authorState.data != null
          ? authorState.data!
          : const <AuthorEntity>[];

      final List<GenreEntity> genres =
          genreState is DataSuccess<List<GenreEntity>> &&
              genreState.data != null
          ? genreState.data!
          : const <GenreEntity>[];

      return ManageMangaLookupResult(
        authors: authors,
        genres: genres,
        authorNameById: ManageMangaHelper.authorLookupFromEntities(authors),
        genreNameById: ManageMangaHelper.genreLookupFromEntities(genres),
      );
    } catch (_) {
      return const ManageMangaLookupResult.empty();
    }
  }

  Future<ManageMangaUpdateResult> updateManga({
    required MangaEntity manga,
    UploadFileData? thumbnailFile,
  }) async {
    final DataState<bool> updateState = await _updateMangaUseCase(
      params: UpdateMangaParams(manga: manga, thumbnailFile: thumbnailFile),
    );

    if (updateState is DataSuccess<bool> && updateState.data == true) {
      return const ManageMangaUpdateResult.success('Cập nhật manga thành công');
    }

    final error = updateState is DataFailed<bool> ? updateState.error : null;

    return ManageMangaUpdateResult.failure(
      ManageMangaHelper.resolveErrorMessage(error),
    );
  }

  Future<ManageMangaCreateResult> createManga({
    required MangaEntity manga,
    UploadFileData? thumbnailFile,
  }) async {
    final DataState<bool> createState = await _createMangaUseCase(
      params: CreateMangaParams(manga: manga, thumbnailFile: thumbnailFile),
    );

    if (createState is DataSuccess<bool> && createState.data == true) {
      return const ManageMangaCreateResult.success('Tạo manga thành công');
    }

    final error = createState is DataFailed<bool> ? createState.error : null;

    return ManageMangaCreateResult.failure(
      ManageMangaHelper.resolveErrorMessage(error),
    );
  }

  Future<ManageMangaDeleteResult> deleteManga(int mangaId) async {
    final DataState<bool> deleteState = await _deleteMangaUseCase(
      params: DeleteMangaParams(mangaId: mangaId),
    );

    if (deleteState is DataSuccess<bool> && deleteState.data == true) {
      return const ManageMangaDeleteResult.success('Xóa manga thành công');
    }

    final error = deleteState is DataFailed<bool> ? deleteState.error : null;

    return ManageMangaDeleteResult.failure(
      ManageMangaHelper.resolveErrorMessage(error),
    );
  }
}

class ManageMangaLookupResult {
  final List<AuthorEntity> authors;
  final List<GenreEntity> genres;
  final Map<int, String> authorNameById;
  final Map<int, String> genreNameById;

  const ManageMangaLookupResult({
    required this.authors,
    required this.genres,
    required this.authorNameById,
    required this.genreNameById,
  });

  const ManageMangaLookupResult.empty()
    : authors = const <AuthorEntity>[],
      genres = const <GenreEntity>[],
      authorNameById = const <int, String>{},
      genreNameById = const <int, String>{};
}

class ManageMangaUpdateResult {
  final bool isSuccess;
  final String message;

  const ManageMangaUpdateResult._({
    required this.isSuccess,
    required this.message,
  });

  const ManageMangaUpdateResult.success(String message)
    : this._(isSuccess: true, message: message);

  const ManageMangaUpdateResult.failure(String message)
    : this._(isSuccess: false, message: message);
}

class ManageMangaCreateResult {
  final bool isSuccess;
  final String message;

  const ManageMangaCreateResult._({
    required this.isSuccess,
    required this.message,
  });

  const ManageMangaCreateResult.success(String message)
    : this._(isSuccess: true, message: message);

  const ManageMangaCreateResult.failure(String message)
    : this._(isSuccess: false, message: message);
}

class ManageMangaDeleteResult {
  final bool isSuccess;
  final String message;

  const ManageMangaDeleteResult._({
    required this.isSuccess,
    required this.message,
  });

  const ManageMangaDeleteResult.success(String message)
    : this._(isSuccess: true, message: message);

  const ManageMangaDeleteResult.failure(String message)
    : this._(isSuccess: false, message: message);
}
