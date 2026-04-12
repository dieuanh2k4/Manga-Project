import 'dart:io';

import 'package:dio/dio.dart';
import 'package:web_admin/core/models/upload_file_data.dart';
import 'package:web_admin/core/resources/data_state.dart';
import 'package:web_admin/data/data_sources/remote/manga_update_api_service.dart';
import 'package:web_admin/data/data_sources/remote/new_api_service.dart';
import 'package:web_admin/data/mappers/manga_mapper.dart';
import 'package:web_admin/domain/entities/manga.dart';
import 'package:web_admin/domain/repository/manga_repository.dart';

class MangaRepoImplement implements MangaRepository {
  final NewApiService _newApiService;
  final MangaUpdateApiService _mangaUpdateApiService;

  MangaRepoImplement(this._newApiService, this._mangaUpdateApiService);

  @override
  Future<DataState<List<MangaEntity>>> getManga() async {
    try {
      final httpResponse = await _newApiService.getManga();

      if (httpResponse.response.statusCode == HttpStatus.ok) {
        return DataSuccess(httpResponse.data.toEntityList());
      } else {
        return DataFailed(
          DioError(
            error: httpResponse.response.statusMessage,
            response: httpResponse.response,
            type: DioErrorType.response,
            requestOptions: httpResponse.response.requestOptions,
          ),
        );
      }
    } on DioError catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<bool>> updateManga(
    MangaEntity manga, {
    UploadFileData? thumbnailFile,
  }) async {
    final int? mangaId = manga.id;
    if (mangaId == null || mangaId <= 0) {
      return DataFailed(
        DioError(
          error: 'ID manga không hợp lệ',
          requestOptions: RequestOptions(path: 'Manga/update-manga'),
          type: DioErrorType.other,
        ),
      );
    }

    try {
      final Response<dynamic> response = await _mangaUpdateApiService
          .updateManga(manga, thumbnailFile: thumbnailFile);

      if (response.statusCode == HttpStatus.ok) {
        return const DataSuccess(true);
      }

      return DataFailed(
        DioError(
          error: response.statusMessage,
          response: response,
          requestOptions: response.requestOptions,
          type: DioErrorType.response,
        ),
      );
    } on DioError catch (e) {
      return DataFailed(e);
    }
  }
}
