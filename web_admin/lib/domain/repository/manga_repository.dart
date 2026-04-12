import 'package:web_admin/core/resources/data_state.dart';
import 'package:web_admin/domain/entities/manga.dart';

abstract class MangaRepository {
  Future<DataState<List<MangaEntity>>> getManga();
}
