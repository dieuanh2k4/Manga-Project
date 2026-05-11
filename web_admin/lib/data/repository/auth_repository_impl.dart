import 'package:dio/dio.dart';
import 'package:web_admin/core/resources/data_state.dart';
import 'package:web_admin/data/data_sources/remote/auth_login_api_service.dart';
import 'package:web_admin/domain/entities/auth.dart';
import 'package:web_admin/domain/repository/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLoginApiService _authLoginApiService;

  AuthRepositoryImpl(this._authLoginApiService);

  @override
  Future<DataState<AuthEntity>> login(String userName, String password) async {
    try {
      final login = await _authLoginApiService.login(userName, password);
      return DataSuccess(login.toEntity());
    } on DioError catch (e) {
      return DataFailed(e);
    }
  }
}
