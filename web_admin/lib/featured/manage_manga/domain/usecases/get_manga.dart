import 'package:web_admin/core/resources/data_state.dart';
import 'package:web_admin/core/usecase/usecase.dart';
import 'package:web_admin/featured/manage_manga/domain/entities/manga.dart';
import 'package:web_admin/featured/manage_manga/domain/repository/manga_repository.dart';

class GetMangaUseCase implements UseCase<DataState<List<MangaEntity>>, void> {
  final MangaRepository _mangaRepository;

  GetMangaUseCase(this._mangaRepository);

  @override
  Future<DataState<List<MangaEntity>>> call({void params}) {
    return _mangaRepository.getManga();
  }
}
