import 'dart:io';

import 'package:dio/dio.dart';
import 'package:web_admin/core/resources/data_state.dart';
import 'package:web_admin/featured/manage_manga/data/data_sources/remote/new_api_service.dart';
import 'package:web_admin/featured/manage_manga/data/mappers/manga_mapper.dart';
import 'package:web_admin/featured/manage_manga/domain/entities/manga.dart';
import 'package:web_admin/featured/manage_manga/domain/repository/manga_repository.dart';

class MangaRepoImplement implements MangaRepository {
  final NewApiService _newApiService;

  MangaRepoImplement(this._newApiService);

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
}
