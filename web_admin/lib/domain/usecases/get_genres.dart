import 'package:web_admin/core/resources/data_state.dart';
import 'package:web_admin/core/usecase/usecase.dart';
import 'package:web_admin/domain/entities/genre.dart';
import 'package:web_admin/domain/repository/lookup_repository.dart';

class GetGenresUseCase implements UseCase<DataState<List<GenreEntity>>, void> {
  final LookupRepository _lookupRepository;

  GetGenresUseCase(this._lookupRepository);

  @override
  Future<DataState<List<GenreEntity>>> call({void params}) {
    return _lookupRepository.getGenres();
  }
}
