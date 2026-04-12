import 'package:dio/dio.dart';
import 'package:web_admin/core/models/upload_file_data.dart';
import 'package:web_admin/core/resources/data_state.dart';
import 'package:web_admin/core/usecase/usecase.dart';
import 'package:web_admin/domain/entities/manga.dart';
import 'package:web_admin/domain/repository/manga_repository.dart';

class UpdateMangaUseCase
    implements UseCase<DataState<bool>, UpdateMangaParams?> {
  final MangaRepository _mangaRepository;

  UpdateMangaUseCase(this._mangaRepository);

  @override
  Future<DataState<bool>> call({UpdateMangaParams? params}) {
    if (params == null) {
      return Future<DataState<bool>>.value(
        DataFailed(
          DioError(
            error: 'Thiếu dữ liệu cập nhật manga',
            requestOptions: RequestOptions(path: 'Manga/update-manga'),
            type: DioErrorType.other,
          ),
        ),
      );
    }

    return _mangaRepository.updateManga(
      params.manga,
      thumbnailFile: params.thumbnailFile,
    );
  }
}

class UpdateMangaParams {
  final MangaEntity manga;
  final UploadFileData? thumbnailFile;

  const UpdateMangaParams({required this.manga, this.thumbnailFile});
}
