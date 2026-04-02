import 'package:web_admin/core/resources/data_state.dart';
import 'package:web_admin/featured/manage_manga/data/models/manga.dart';
import 'package:web_admin/featured/manage_manga/domain/repository/manga_repository.dart';

class MangaRepoImplement implements MangaRepository {
  @override
  Future<DataState<List<MangaModel>>> getManga() {
    throw UnimplementedError();
  }
}
