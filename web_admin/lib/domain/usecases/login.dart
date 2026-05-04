import 'package:web_admin/core/resources/data_state.dart';
import 'package:web_admin/domain/entities/auth.dart';
import 'package:web_admin/domain/repository/auth_repository.dart';

class Login {
  final AuthRepository _repository;

  Login(this._repository);

  Future<DataState<AuthEntity>> call(String userName, String password) {
    return _repository.login(userName, password);
  }
}
