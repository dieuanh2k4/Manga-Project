import 'package:web_admin/core/resources/data_state.dart';
import 'package:web_admin/core/usecase/usecase.dart';
import 'package:web_admin/domain/entities/author.dart';
import 'package:web_admin/domain/repository/lookup_repository.dart';

class GetAuthorsUseCase
    implements UseCase<DataState<List<AuthorEntity>>, void> {
  final LookupRepository _lookupRepository;

  GetAuthorsUseCase(this._lookupRepository);

  @override
  Future<DataState<List<AuthorEntity>>> call({void params}) {
    return _lookupRepository.getAuthors();
  }
}
