import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<void> call(RegisterPayload payload) {
    return repository.register(payload);
  }
}
