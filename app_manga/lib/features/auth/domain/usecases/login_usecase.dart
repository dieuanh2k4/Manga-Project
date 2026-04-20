import '../entities/auth_session_entity.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<AuthSessionEntity> call(String userName, String password) {
    return repository.login(userName, password);
  }
}
