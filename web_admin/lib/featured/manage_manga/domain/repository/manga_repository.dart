import 'package:web_admin/core/resources/data_state.dart';
import 'package:web_admin/featured/manage_manga/domain/entities/manga.dart';

abstract class MangaRepository {
  Future<DataState<List<MangaEntity>>> getManga();
}
