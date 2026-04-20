import '../entities/auth_session_entity.dart';
import '../repositories/auth_repository.dart';

class RestoreSessionUseCase {
  final AuthRepository repository;

  RestoreSessionUseCase(this.repository);

  Future<AuthSessionEntity?> call() {
    return repository.restoreSession();
  }
}
