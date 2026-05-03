import 'package:dio/dio.dart';
import 'package:web_admin/core/models/upload_file_data.dart';
import 'package:web_admin/core/resources/data_state.dart';
import 'package:web_admin/core/usecase/usecase.dart';
import 'package:web_admin/domain/entities/manga.dart';
import 'package:web_admin/domain/repository/manga_repository.dart';

class CreateMangaUseCase
    implements UseCase<DataState<bool>, CreateMangaParams?> {
  final MangaRepository _mangaRepository;

  CreateMangaUseCase(this._mangaRepository);

  @override
  Future<DataState<bool>> call({CreateMangaParams? params}) {
    if (params == null) {
      return Future<DataState<bool>>.value(
        DataFailed(
          DioError(
            error: 'Thiếu dữ liệu tạo manga',
            requestOptions: RequestOptions(path: 'Manga/create-manga'),
            type: DioErrorType.other,
          ),
        ),
      );
    }

    return _mangaRepository.createManga(
      params.manga,
      thumbnailFile: params.thumbnailFile,
    );
  }
}

class CreateMangaParams {
  final MangaEntity manga;
  final UploadFileData? thumbnailFile;

  const CreateMangaParams({required this.manga, this.thumbnailFile});
}
