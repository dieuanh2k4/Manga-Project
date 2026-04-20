import '../entities/reader_profile_entity.dart';
import '../repositories/auth_repository.dart';

class GetMyProfileUseCase {
  final AuthRepository repository;

  GetMyProfileUseCase(this.repository);

  Future<ReaderProfileEntity> call(String token) {
    return repository.getMyProfile(token);
  }
}
