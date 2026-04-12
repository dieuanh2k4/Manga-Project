import 'package:web_admin/core/resources/data_state.dart';
import 'package:web_admin/domain/entities/author.dart';
import 'package:web_admin/domain/entities/genre.dart';

abstract class LookupRepository {
  Future<DataState<List<AuthorEntity>>> getAuthors();

  Future<DataState<List<GenreEntity>>> getGenres();
}
