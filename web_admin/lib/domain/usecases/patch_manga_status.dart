import 'package:web_admin/core/resources/data_state.dart';
import 'package:web_admin/core/usecase/usecase.dart';
import 'package:web_admin/domain/repository/manga_repository.dart';

class PatchMangaStatusParams {
  final int mangaId;
  final String status;

  const PatchMangaStatusParams({required this.mangaId, required this.status});
}

class PatchMangaStatusUseCase
    implements UseCase<DataState<bool>, PatchMangaStatusParams> {
  final MangaRepository _mangaRepository;

  const PatchMangaStatusUseCase(this._mangaRepository);

  @override
  Future<DataState<bool>> call({PatchMangaStatusParams? params}) async {
    if (params == null) {
      throw ArgumentError('PatchMangaStatusParams is required');
    }
    return _mangaRepository.patchMangaStatus(params.mangaId, params.status);
  }
}
