import 'package:dio/dio.dart';
import 'package:web_admin/core/resources/data_state.dart';
import 'package:web_admin/core/usecase/usecase.dart';
import 'package:web_admin/domain/repository/manga_repository.dart';

class DeleteMangaUseCase
    implements UseCase<DataState<bool>, DeleteMangaParams?> {
  final MangaRepository _mangaRepository;

  DeleteMangaUseCase(this._mangaRepository);

  @override
  Future<DataState<bool>> call({DeleteMangaParams? params}) {
    if (params == null) {
      return Future<DataState<bool>>.value(
        DataFailed(
          DioError(
            error: 'Thiếu dữ liệu xóa manga',
            requestOptions: RequestOptions(path: 'Manga/delete-manga'),
            type: DioErrorType.other,
          ),
        ),
      );
    }

    return _mangaRepository.deleteManga(params.mangaId);
  }
}

class DeleteMangaParams {
  final int mangaId;

  const DeleteMangaParams({required this.mangaId});
}
