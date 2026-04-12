import 'package:dio/dio.dart';
import 'package:web_admin/core/resources/data_state.dart';
import 'package:web_admin/data/data_sources/remote/lookup_api_service.dart';
import 'package:web_admin/data/mappers/author_mapper.dart';
import 'package:web_admin/data/mappers/genre_mapper.dart';
import 'package:web_admin/domain/entities/author.dart';
import 'package:web_admin/domain/entities/genre.dart';
import 'package:web_admin/domain/repository/lookup_repository.dart';

class LookupRepoImplement implements LookupRepository {
  final LookupApiService _lookupApiService;

  LookupRepoImplement(this._lookupApiService);

  @override
  Future<DataState<List<AuthorEntity>>> getAuthors() async {
    try {
      final authors = await _lookupApiService.getAllAuthors();
      return DataSuccess(authors.toEntityList());
    } on DioError catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<List<GenreEntity>>> getGenres() async {
    try {
      final genres = await _lookupApiService.getAllGenres();
      return DataSuccess(genres.toEntityList());
    } on DioError catch (e) {
      return DataFailed(e);
    }
  }
}
